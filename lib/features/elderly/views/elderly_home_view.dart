import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/models/models.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/elderly_provider.dart';
import '../widgets/pairing_code_modal.dart';

String _formatReminderDateTime(String dateStr, String timeStr) {
  try {
    final parsedDate = dateStr == 'Today' || dateStr.isEmpty
        ? DateTime.now()
        : DateFormat('yyyy-MM-dd').parse(dateStr);
    DateTime parsedTime;
    try {
      parsedTime = DateFormat('HH:mm:ss').parse(timeStr);
    } catch (_) {
      parsedTime = DateFormat('hh:mm a').parse(timeStr);
    }
    final combined = DateTime(
      parsedDate.year,
      parsedDate.month,
      parsedDate.day,
      parsedTime.hour,
      parsedTime.minute,
    );
    return DateFormat('EEE, MMM d - h:mm a').format(combined);
  } catch (_) {
    return '$dateStr - $timeStr';
  }
}

class ElderlyView extends ConsumerStatefulWidget {
  const ElderlyView({super.key});

  @override
  ConsumerState<ElderlyView> createState() => _ElderlyViewState();
}

class _ElderlyViewState extends ConsumerState<ElderlyView> {
  int _reminderIndex = 0;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(elderlyProvider.notifier).fetchReminders());
  }

  Future<void> _logMood(String moodLabel) async {
    final saved = await ref.read(elderlyProvider.notifier).logMood(moodLabel);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          saved
              ? 'Your mood was saved as $moodLabel.'
              : 'We could not save your mood. Please try again.',
        ),
        backgroundColor:
            saved ? const Color(0xFF118A36) : const Color(0xFFB91C1C),
      ),
    );
  }

  void _showPairingCodeModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => const PairingCodeModal(),
    );
  }

  void _moveReminder(int direction, int reminderCount) {
    if (reminderCount < 2) return;
    setState(() {
      _reminderIndex =
          (_reminderIndex + direction + reminderCount) % reminderCount;
    });
  }

  Future<void> _toggleReminderSound(ElderlyNotifier notifier) async {
    final enabled = await notifier.toggleAudio();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          enabled
              ? 'Reminder sound is on. A sample sound was played.'
              : 'Reminder sound is muted.',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(elderlyProvider);
    final notifier = ref.read(elderlyProvider.notifier);
    final activeElderlyId = ref.watch(authProvider).user?.id ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF7FBFF),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : !state.isLinked
              ? _buildUnlinkedOnboardingView(context)
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final textScale =
                        MediaQuery.textScalerOf(context).scale(1.0);
                    final compact =
                        constraints.maxHeight >= 620 && textScale <= 1.15;
                    return RefreshIndicator(
                      onRefresh: notifier.fetchReminders,
                      color: const Color(0xFF1D4ED8),
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(8, 12, 8, 24),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: math.max(0, constraints.maxHeight - 36),
                          ),
                          child: _buildActiveDashboard(
                            state,
                            notifier,
                            activeElderlyId,
                            compact: compact,
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  Widget _buildUnlinkedOnboardingView(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: [
        Container(
          padding: const EdgeInsets.all(28),
          decoration: _cardDecoration(),
          child: Column(
            children: [
              const Icon(Icons.qr_code_2, size: 72, color: Color(0xFF1D4ED8)),
              const SizedBox(height: 20),
              const Text(
                'Connect your care team',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Create an invitation code for a trusted caregiver or family member.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 17,
                  color: Color(0xFF334155),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: () => _showPairingCodeModal(context),
                  icon: const Icon(Icons.key, size: 24),
                  label: const Text(
                    'Create invitation code',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActiveDashboard(
    ElderlyState state,
    ElderlyNotifier notifier,
    String activeElderlyId, {
    required bool compact,
  }) {
    final reminders = state.reminders;
    final currentIndex = reminders.isEmpty
        ? 0
        : _reminderIndex.clamp(0, reminders.length - 1).toInt();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildEmergencyCard(state, notifier, compact: compact),
        SizedBox(height: compact ? 12 : 18),
        _buildReminderSection(
          state,
          notifier,
          reminders,
          currentIndex,
          activeElderlyId,
          compact: compact,
        ),
        SizedBox(height: compact ? 12 : 18),
        _buildMoodSection(compact: compact),
      ],
    );
  }

  Widget _buildEmergencyCard(
    ElderlyState state,
    ElderlyNotifier notifier, {
    required bool compact,
  }) {
    final isActive = state.isSosActive;
    return Semantics(
      button: true,
      label: isActive
          ? 'Emergency alert active. Tap to stop the local alarm.'
          : 'Send emergency alert to caregivers and family.',
      child: Material(
        color: isActive ? const Color(0xFF111827) : const Color(0xFFB91C1C),
        borderRadius: BorderRadius.circular(28),
        elevation: 5,
        shadowColor: const Color(0x55B91C1C),
        child: InkWell(
          onTap: isActive ? notifier.resolveSOS : notifier.triggerSOS,
          borderRadius: BorderRadius.circular(28),
          child: Container(
            width: double.infinity,
            constraints: BoxConstraints(minHeight: compact ? 112 : 150),
            padding: EdgeInsets.symmetric(
              horizontal: 20,
              vertical: compact ? 14 : 22,
            ),
            child: Row(
              children: [
                Container(
                  width: compact ? 64 : 76,
                  height: compact ? 64 : 76,
                  decoration: const BoxDecoration(
                    color: Color(0x26FFFFFF),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isActive
                        ? Icons.check_circle_outline
                        : Icons.sos_rounded,
                    size: compact ? 42 : 50,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isActive ? 'Help is on the way' : 'Emergency help',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: compact ? 24 : 28,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isActive
                            ? 'Caregivers and family were notified.'
                            : 'Tap here to alert your care team.',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: compact ? 15 : 17,
                          height: 1.3,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReminderSection(
    ElderlyState state,
    ElderlyNotifier notifier,
    List<Reminder> reminders,
    int currentIndex,
    String activeElderlyId, {
    required bool compact,
  }) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 14 : 18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.notifications_active_outlined,
                color: Color(0xFFB91C1C),
                size: 28,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Reminders',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
              Semantics(
                button: true,
                toggled: state.isAudioEnabled,
                label: state.isAudioEnabled
                    ? 'Reminder sound on. Tap to mute.'
                    : 'Reminder sound muted. Tap to turn on and play a sample.',
                child: OutlinedButton.icon(
                  key: const Key('elderly_sound_toggle'),
                  onPressed: () => _toggleReminderSound(notifier),
                  icon: Icon(
                    state.isAudioEnabled
                        ? Icons.volume_up_rounded
                        : Icons.volume_off_rounded,
                    size: 22,
                  ),
                  label: Text(state.isAudioEnabled ? 'Sound on' : 'Muted'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(112, 48),
                    foregroundColor: state.isAudioEnabled
                        ? const Color(0xFF1D4ED8)
                        : const Color(0xFF475569),
                    side: BorderSide(
                      width: 2,
                      color: state.isAudioEnabled
                          ? const Color(0xFF93C5FD)
                          : const Color(0xFFCBD5E1),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: compact ? 10 : 14),
          if (reminders.isEmpty)
            const SizedBox(
              height: 112,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.task_alt_rounded,
                      size: 42,
                      color: Color(0xFF15803D),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'No reminders right now',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF334155),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            GestureDetector(
              onHorizontalDragEnd: (details) {
                final velocity = details.primaryVelocity ?? 0;
                if (velocity.abs() < 150) return;
                _moveReminder(velocity < 0 ? 1 : -1, reminders.length);
              },
              child: AnimatedSwitcher(
                duration: reduceMotion
                    ? Duration.zero
                    : const Duration(milliseconds: 220),
                transitionBuilder: (child, animation) => reduceMotion
                    ? child
                    : FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0.05, 0),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        ),
                      ),
                child: _buildReminderCard(
                  reminders[currentIndex],
                  notifier,
                  activeElderlyId,
                  compact: compact,
                  key: ValueKey(reminders[currentIndex].id),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: reminders.length > 1
                        ? () => _moveReminder(-1, reminders.length)
                        : null,
                    icon: const Icon(Icons.arrow_back_rounded),
                    label: const Text('Previous'),
                    style: _carouselButtonStyle(),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Semantics(
                    liveRegion: true,
                    label:
                        'Reminder ${currentIndex + 1} of ${reminders.length}',
                    child: Text(
                      '${currentIndex + 1} / ${reminders.length}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF334155),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: reminders.length > 1
                        ? () => _moveReminder(1, reminders.length)
                        : null,
                    icon: const Icon(Icons.arrow_forward_rounded),
                    label: const Text('Next'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      backgroundColor: const Color(0xFF075DBB),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: const Color(0xFFE2E8F0),
                      disabledForegroundColor: const Color(0xFF64748B),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  ButtonStyle _carouselButtonStyle() {
    return OutlinedButton.styleFrom(
      minimumSize: const Size.fromHeight(48),
      foregroundColor: const Color(0xFF1D4ED8),
      side: const BorderSide(color: Color(0xFF93C5FD), width: 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    );
  }

  Widget _buildReminderCard(
    Reminder reminder,
    ElderlyNotifier notifier,
    String activeElderlyId, {
    required bool compact,
    required Key key,
  }) {
    final isCompleted = reminder.isCompleted;
    return Container(
      key: key,
      width: double.infinity,
      constraints: BoxConstraints(minHeight: compact ? 118 : 146),
      padding: EdgeInsets.all(compact ? 12 : 16),
      decoration: BoxDecoration(
        color: isCompleted ? const Color(0xFFF0FDF4) : const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isCompleted ? const Color(0xFF86EFAC) : const Color(0xFF93C5FD),
          width: 2,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            isCompleted ? Icons.task_alt_rounded : Icons.alarm_rounded,
            size: compact ? 38 : 44,
            color: isCompleted
                ? const Color(0xFF15803D)
                : const Color(0xFF1D4ED8),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reminder.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 19,
                    height: 1.2,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  _formatReminderDateTime(reminder.date, reminder.time),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E3A8A),
                  ),
                ),
                if (reminder.dosageOrLocation?.isNotEmpty == true) ...[
                  const SizedBox(height: 3),
                  Text(
                    reminder.dosageOrLocation!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Color(0xFF334155),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: compact ? 74 : 88,
            height: compact ? 58 : 66,
            child: ElevatedButton(
              onPressed: isCompleted
                  ? null
                  : () => notifier.confirmMedication(
                        reminder.id,
                        elderlyId: activeElderlyId,
                      ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                backgroundColor: const Color(0xFF15803D),
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFFDCFCE7),
                disabledForegroundColor: const Color(0xFF166534),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                isCompleted ? 'Done' : 'Mark\ndone',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoodSection({required bool compact}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 14 : 18),
      decoration: _cardDecoration(borderColor: const Color(0xFFBFDBFE)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'How are you feeling?',
            style: TextStyle(
              fontSize: compact ? 20 : 22,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF0F172A),
            ),
          ),
          SizedBox(height: compact ? 10 : 14),
          Row(
            children: [
              Expanded(
                child: _buildFeelingButton(
                  icon: Icons.sentiment_very_satisfied_rounded,
                  label: 'Good',
                  moodValue: 'Happy',
                  background: const Color(0xFFF0FDF4),
                  foreground: const Color(0xFF166534),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildFeelingButton(
                  icon: Icons.sentiment_neutral_rounded,
                  label: 'Okay',
                  moodValue: 'Neutral',
                  background: const Color(0xFFFEFCE8),
                  foreground: const Color(0xFF854D0E),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildFeelingButton(
                  icon: Icons.sentiment_dissatisfied_rounded,
                  label: 'Not well',
                  moodValue: 'Sad',
                  background: const Color(0xFFFEF2F2),
                  foreground: const Color(0xFF991B1B),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeelingButton({
    required IconData icon,
    required String label,
    required String moodValue,
    required Color background,
    required Color foreground,
  }) {
    return Semantics(
      button: true,
      label: 'I feel $label',
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => _logMood(moodValue),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            constraints: const BoxConstraints(minHeight: 72),
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: foreground.withOpacity(0.35), width: 2),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 32, color: foreground),
                const SizedBox(height: 3),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: foreground,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  BoxDecoration _cardDecoration({
    Color borderColor = const Color(0xFFE2E8F0),
  }) {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: borderColor, width: 2),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0D0F172A),
          blurRadius: 12,
          offset: Offset(0, 4),
        ),
      ],
    );
  }
}
