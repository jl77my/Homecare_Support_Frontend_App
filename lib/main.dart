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
      title: 'HomeCare',
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
                        backgroundColor: const Color(0xFFE5F2FF),
                        backgroundImage: user.profilePhotoUrl != null && user.profilePhotoUrl!.startsWith('data:image')
                            ? MemoryImage(base64Decode(user.profilePhotoUrl!.split(',')[1]))
                            : (user.profilePhotoUrl != null ? NetworkImage(user.profilePhotoUrl!) as ImageProvider : null),
                        child: user.profilePhotoUrl == null
                            ? Text(
                                user.name.isNotEmpty ? user.name.substring(0, 1).toUpperCase() : 'U',
                                style: const TextStyle(color: AppTheme.primaryBlue, fontSize: 12, fontWeight: FontWeight.bold),
                              )
                            : null,
                      ),
                    ),
                  ),
                ],
              ),
              body: LayoutBuilder(
                builder: (context, constraints) => Stack(
                  children: [
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: user.role.toLowerCase() == 'elderly' && _activeTab != 'profile' && _activeTab != 'account_settings'
                            ? const ElderlyView()
                            : _buildMainContent(user.role),
                      ),
                    ),
                    if (user.role.toLowerCase() != 'elderly' && _activeTab != 'agent')
                      DraggableCareAgentButton(
                        availableSize: Size(constraints.maxWidth, constraints.maxHeight),
                        onPressed: () => _setActiveTab('agent'),
                      ),
                    const GlobalReminderOverlay(),
                    if (user.role.toLowerCase() != 'elderly') const GlobalSosOverlay(),
                  ],
                ),
              ),
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

class DraggableCareAgentButton extends StatefulWidget {
  final Size availableSize;
  final VoidCallback onPressed;

  const DraggableCareAgentButton({
    super.key,
    required this.availableSize,
    required this.onPressed,
  });

  @override
  State<DraggableCareAgentButton> createState() => _DraggableCareAgentButtonState();
}

class _DraggableCareAgentButtonState extends State<DraggableCareAgentButton> {
  static const double _buttonWidth = 148;
  static const double _buttonHeight = 52;
  static const double _edgePadding = 12;
  Offset? _position;

  Offset _clamp(Offset value) {
    final maxX = (widget.availableSize.width - _buttonWidth - _edgePadding).clamp(_edgePadding, double.infinity).toDouble();
    final maxY = (widget.availableSize.height - _buttonHeight - _edgePadding).clamp(_edgePadding, double.infinity).toDouble();
    return Offset(
      value.dx.clamp(_edgePadding, maxX).toDouble(),
      value.dy.clamp(_edgePadding, maxY).toDouble(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final initial = Offset(
      widget.availableSize.width - _buttonWidth - 16,
      widget.availableSize.height - _buttonHeight - 16,
    );
    final position = _clamp(_position ?? initial);

    return Positioned(
      left: position.dx,
      top: position.dy,
      width: _buttonWidth,
      height: _buttonHeight,
      child: Semantics(
        button: true,
        label: 'Open Care Agent. Drag to move this button.',
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanUpdate: (details) => setState(() => _position = _clamp(position + details.delta)),
          onTap: widget.onPressed,
          child: Material(
            color: AppTheme.primaryBlue,
            elevation: 5,
            shadowColor: AppTheme.primaryBlue.withOpacity(.25),
            borderRadius: BorderRadius.circular(16),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.drag_indicator_rounded, color: Colors.white, size: 19),
                  SizedBox(width: 4),
                  Icon(Icons.smart_toy_outlined, color: Colors.white, size: 20),
                  SizedBox(width: 7),
                  Text('Care Agent', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
