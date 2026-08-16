// lib/core/widgets/bottom_navigation_bar.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/family/providers/family_provider.dart';
import '../../features/caregiver/providers/caregiver_provider.dart';
import '../../features/elderly/providers/elderly_provider.dart';
import '../models/enums.dart';
import '../theme/app_theme.dart';

class CustomBottomNavigationBar extends ConsumerWidget {
  final String activeTab;
  final ValueChanged<String> onTabSelected;

  const CustomBottomNavigationBar({
    super.key,
    required this.activeTab,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    if (user == null) return const SizedBox.shrink();

    final isFamily = user.role.toLowerCase() == 'family';
    final isCaregiver = user.role.toLowerCase() == 'caregiver';

    final pendingReminders = ref.watch(elderlyProvider).reminders.where((r) => !r.isCompleted).length;
    final unacknowledgedReports = isFamily ? ref.watch(familyDashboardProvider).reports.length : 0;
    
    int unreadChats = 0;
    int pendingTasks = 0; 

    if (isFamily) {
      final familyState = ref.watch(familyDashboardProvider);
      unreadChats = familyState.unreadCounts.values.fold(0, (sum, count) => sum + count);
      pendingTasks = familyState.tasks.where((t) => t.status == TaskStatus.pending).length;
    } else if (isCaregiver) {
      final caregiverState = ref.watch(caregiverProvider);
      unreadChats = caregiverState.unreadCounts.values.fold(0, (sum, count) => sum + count);
      pendingTasks = caregiverState.tasks.where((t) => t.status == TaskStatus.pending).length;
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14075DBB),
            blurRadius: 16,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(context, 'status', Icons.grid_view_rounded, 'Board', activeTab),
          _buildNavItem(
            context,
            'reports',
            Icons.assignment_outlined,
            'Reports',
            activeTab,
            badgeCount: unacknowledgedReports,
            badgeColor: const Color(0xFF075DBB),
          ),
          _buildNavItem(
            context,
            'reminders',
            Icons.notifications_active_outlined,
            'Reminders',
            activeTab,
            badgeCount: pendingReminders,
            badgeColor: const Color(0xFFEF4444),
          ),
          _buildNavItem(
            context,
            'tasks',
            Icons.check_box_outlined,
            'Tasks',
            activeTab,
            badgeCount: pendingTasks,
            badgeColor: const Color(0xFFF59E0B), 
          ),
          _buildNavItem(
            context,
            'chat',
            Icons.chat_bubble_outline,
            'Connect',
            activeTab,
            badgeCount: unreadChats,
            badgeColor: const Color(0xFF10B981),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    String tabKey,
    IconData icon,
    String label,
    String activeTab, {
    int badgeCount = 0,
    Color badgeColor = Colors.red,
  }) {
    final isSelected = activeTab == tabKey;
    return InkWell(
      onTap: () => onTabSelected(tabKey),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE5F2FF) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  icon,
                  color: isSelected ? AppTheme.primaryBlue : AppTheme.textMuted,
                  size: 22,
                ),
                if (badgeCount > 0)
                  Positioned(
                    top: -4,
                    right: -6,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: badgeColor,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                      child: Text(
                        '$badgeCount',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                color: isSelected ? AppTheme.primaryBlue : AppTheme.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
