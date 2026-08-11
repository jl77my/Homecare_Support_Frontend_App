// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import 'core/theme/app_theme.dart';
import 'core/widgets/bottom_navigation_bar.dart';
import 'core/widgets/global_sos_overlay.dart';
import 'core/widgets/global_reminder_overlay.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/auth/views/auth_flow_view.dart';
import 'features/caregiver/views/account_settings_view.dart';
import 'features/caregiver/views/caregiver_status_view.dart';
import 'features/caregiver/views/chat_view.dart';
import 'features/caregiver/views/profile_view.dart';
import 'features/caregiver/views/reports_view.dart';
import 'features/caregiver/views/tasks_view.dart';
import 'features/elderly/views/elderly_home_view.dart';
import 'features/elderly/views/reminders_view.dart';
import 'features/family/views/family_dashboard_view.dart';
import 'features/agent/views/agent_chat_view.dart';

void main() {
  runApp(
    const ProviderScope(
      child: HomeCareApp(),
    ),
  );
}

class HomeCareApp extends ConsumerStatefulWidget {
  const HomeCareApp({super.key});

  @override
  ConsumerState<HomeCareApp> createState() => _HomeCareAppState();
}

class _HomeCareAppState extends ConsumerState<HomeCareApp> {
  String _activeTab = 'status';
  late final ProviderSubscription<String?> _authUserSubscription;

  @override
  void initState() {
    super.initState();
    _authUserSubscription = ref.listenManual<String?>(
      authProvider.select((state) => state.user?.id),
      (previousUserId, currentUserId) {
        if (currentUserId != null && currentUserId != previousUserId && mounted) {
          setState(() => _activeTab = 'status');
        }
      },
    );
  }

  @override
  void dispose() {
    _authUserSubscription.close();
    super.dispose();
  }

  void _setActiveTab(String tabKey) {
    setState(() {
      _activeTab = tabKey;
    });
  }

  void _goToDashboard() => _setActiveTab('status');

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    return MaterialApp(
      title: 'HomeCare Pro',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: user == null
          ? const AuthFlowView()
          : Scaffold(
              appBar: AppBar(
                titleSpacing: 8,
                title: Semantics(
                  button: true,
                  label: 'Go to dashboard',
                  child: InkWell(
                    key: const Key('homecare_dashboard_button'),
                    onTap: _goToDashboard,
                    borderRadius: BorderRadius.circular(14),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF4444).withOpacity(0.12),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.24)),
                            ),
                            child: const Icon(Icons.favorite, color: Color(0xFFEF4444), size: 22),
                          ),
                          const SizedBox(width: 10),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('HomeCare', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                              Text(
                                'CONNECTED SENIOR SUPPORT',
                                style: TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF94A3B8),
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                actions: [
                  GestureDetector(
                    onTap: () => _setActiveTab('profile'),
                    child: Padding(
                      padding: const EdgeInsets.only(right: 16, left: 4),
                      child: CircleAvatar(
                        radius: 16,
                        backgroundColor: const Color(0xFF0F172A),
                        backgroundImage: user.profilePhotoUrl != null && user.profilePhotoUrl!.startsWith('data:image')
                            ? MemoryImage(base64Decode(user.profilePhotoUrl!.split(',')[1]))
                            : (user.profilePhotoUrl != null ? NetworkImage(user.profilePhotoUrl!) as ImageProvider : null),
                        child: user.profilePhotoUrl == null
                            ? Text(
                                user.name.isNotEmpty ? user.name.substring(0, 1).toUpperCase() : 'U',
                                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                              )
                            : null,
                      ),
                    ),
                  ),
                ],
              ),
              body: Stack(
                children: [
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: user.role.toLowerCase() == 'elderly' && _activeTab != 'profile' && _activeTab != 'account_settings'
                          ? const ElderlyView()
                          : _buildMainContent(user.role),
                    ),
                  ),
                  if (user.role.toLowerCase() != 'elderly') const GlobalSosOverlay(),
                  const GlobalReminderOverlay(),
                ],
              ),
              floatingActionButton: user.role.toLowerCase() != 'elderly' && _activeTab != 'agent'
                  ? FloatingActionButton.extended(
                      onPressed: () => _setActiveTab('agent'),
                      icon: const Icon(Icons.smart_toy_outlined),
                      label: const Text('Care Agent'),
                    )
                  : null,
              bottomNavigationBar: user.role.toLowerCase() == 'elderly'
                  ? null
                  : CustomBottomNavigationBar(
                      activeTab: _activeTab,
                      onTabSelected: _setActiveTab,
                    ),
            ),
    );
  }

  Widget _buildMainContent(String userRole) {
    switch (_activeTab) {
      case 'status':
        return (userRole.toLowerCase() == 'family')
            ? FamilyDashboardView(
                onNavigateToReports: () => _setActiveTab('reports'),
              )
            : CaregiverStatusView(
                onNavigateToReports: () => _setActiveTab('reports'),
              );
      case 'reports':
        return const ReportsView();
      case 'reminders':
        return const RemindersView();
      case 'tasks':
        return const TasksView();
      case 'chat':
        return const ChatView();
      case 'agent':
        return const AgentChatView();
      case 'profile':
        return ProfileView(
          onNavigateToAccountSettings: () => _setActiveTab('account_settings'),
        );
      case 'account_settings':
        return AccountSettingsView(onBack: () => _setActiveTab('profile'));
      default:
        return userRole.toLowerCase() == 'family'
            ? FamilyDashboardView(
                onNavigateToReports: () => _setActiveTab('reports'),
              )
            : CaregiverStatusView(
                onNavigateToReports: () => _setActiveTab('reports'),
              );
    }
  }
}
