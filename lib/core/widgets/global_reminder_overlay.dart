// lib/core/widgets/global_reminder_overlay.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/elderly/providers/elderly_provider.dart';
import '../../features/caregiver/providers/caregiver_provider.dart';
import '../../features/auth/providers/auth_provider.dart';

class GlobalReminderOverlay extends ConsumerWidget {
  const GlobalReminderOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    if (user == null) return const SizedBox.shrink();

    String? reminderMsg;
    VoidCallback? onResolve;

    if (user.role.toLowerCase() == 'elderly') {
      final state = ref.watch(elderlyProvider);
      reminderMsg = state.activeReminderMessage;
      onResolve = ref.read(elderlyProvider.notifier).resolveReminder;
    } else if (user.role.toLowerCase() == 'caregiver') {
      final state = ref.watch(caregiverProvider);
      reminderMsg = state.activeReminderMessage;
      onResolve = ref.read(caregiverProvider.notifier).resolveReminder;
    }

    if (reminderMsg == null) return const SizedBox.shrink();

    return Positioned(
      top: 100,
      left: 16,
      right: 16,
      child: Material(
        elevation: 12,
        borderRadius: BorderRadius.circular(24),
        color: const Color(0xFF075DBB),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFF60A5FA), width: 2),
          ),
          child: Row(
            children: [
              const Icon(Icons.medication, color: Colors.white, size: 36),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'MEDICATION ALARM!',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.8),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      reminderMsg,
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: onResolve,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF075DBB),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Dismiss', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}