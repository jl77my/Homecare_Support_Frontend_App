// lib/core/widgets/bottom_navigation_bar.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/caregiver/providers/caregiver_provider.dart';
import '../../features/elderly/providers/elderly_provider.dart';

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
    final pendingReminders = ref.watch(elderlyProvider).reminders.where((r) => !r.isCompleted).length;
    final unacknowledgedReports = ref.watch(caregiverProvider).reports.length;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(32),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 20,
            offset: Offset(0, 10),
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
            badgeColor: const Color(0xFF2563EB),
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
          _buildNavItem(context, 'tasks', Icons.check_box_outlined, 'Tasks', activeTab),
          _buildNavItem(context, 'chat', Icons.chat_bubble_outline, 'Connect', activeTab),
          _buildNavItem(context, 'profile', Icons.person_outline, 'Profile', activeTab),
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
          color: isSelected ? Colors.white.withOpacity(0.15) : Colors.transparent,
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
                  color: isSelected ? Colors.white : const Color(0xFF94A3B8),
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
                color: isSelected ? Colors.white : const Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}