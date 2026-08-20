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

    Future.microtask(
      () => ref.read(elderlyProvider.notifier).fetchReminders(),
    );
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
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(28),
        ),
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
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : !state.isLinked
              ? _buildUnlinkedOnboardingView(context)
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final textScale =
                        MediaQuery.textScalerOf(context).scale(1.0);

                    final compact =
                        constraints.maxHeight < 700 || textScale > 1.05;

                    return Padding(
                      padding: const EdgeInsets.all(8),
                      child: SizedBox(
                        height: constraints.maxHeight - 16,
                        child: _buildActiveDashboard(
                          state,
                          notifier,
                          activeElderlyId,
                          compact: compact,
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
              const Icon(
                Icons.qr_code_2,
                size: 72,
                color: Color(0xFF1D4ED8),
              ),
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
                  icon: const Icon(
                    Icons.key,
                    size: 24,
                  ),
                  label: const Text(
                    'Create invitation code',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
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
      children: [
        Expanded(
          child: _buildEmergencyCard(
            state,
            notifier,
            compact: compact,
          ),
        ),
        SizedBox(
          height: compact ? 8 : 10,
        ),
        Expanded(
          child: _buildReminderSection(
            state,
            notifier,
            reminders,
            currentIndex,
            activeElderlyId,
            compact: compact,
          ),
        ),
        SizedBox(
          height: compact ? 8 : 10,
        ),
        Expanded(
          child: _buildMoodSection(
            compact: compact,
          ),
        ),
      ],
    );
  }

  Widget _buildEmergencyCard(
    ElderlyState state,
    ElderlyNotifier notifier, {
    required bool compact,
  }) {
    final isActive = state.isSosActive;

    return LayoutBuilder(
      builder: (context, constraints) {
        final h = constraints.maxHeight;
        final w = constraints.maxWidth;

        final short = h < 150;
        final veryShort = h < 125;

        final iconDiameter = (h * 0.42).clamp(46.0, 70.0);
        final iconSize = (iconDiameter * 0.62).clamp(28.0, 44.0);
        final titleSize = (h * 0.15).clamp(18.0, 25.0);
        final subtitleSize = (h * 0.095).clamp(12.0, 16.0);

        final horizontalPadding =
            (w * 0.045).clamp(12.0, 20.0);

        final verticalPadding =
            (h * 0.08).clamp(8.0, 14.0);

        return Semantics(
          button: true,
          label: isActive
              ? 'Emergency alert active. Tap to stop the local alarm.'
              : 'Send emergency alert to caregivers and family.',
          child: Material(
            color:
                isActive ? const Color(0xFF111827) : const Color(0xFFB91C1C),
            borderRadius: BorderRadius.circular(28),
            elevation: 5,
            shadowColor: const Color(0x55B91C1C),
            child: InkWell(
              onTap:
                  isActive ? notifier.resolveSOS : notifier.triggerSOS,
              borderRadius: BorderRadius.circular(28),
              child: Container(
                width: double.infinity,
                height: double.infinity,
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: verticalPadding,
                ),
                child: Row(
                  children: [
                    Container(
                      width: iconDiameter,
                      height: iconDiameter,
                      decoration: const BoxDecoration(
                        color: Color(0x26FFFFFF),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isActive
                            ? Icons.check_circle_outline
                            : Icons.sos_rounded,
                        size: iconSize,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(
                      width: (w * 0.04).clamp(10.0, 18.0),
                    ),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              isActive
                                  ? 'Help is on the way'
                                  : 'Emergency help',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: titleSize,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          if (!veryShort) ...[
                            SizedBox(
                              height: short ? 2 : 4,
                            ),
                            Text(
                              isActive
                                  ? 'Caregivers and family were notified.'
                                  : 'Tap here to alert your care team.',
                              maxLines: short ? 1 : 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: subtitleSize,
                                height: 1.2,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
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
    final reduceMotion =
        MediaQuery.disableAnimationsOf(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final h = constraints.maxHeight;
        final w = constraints.maxWidth;

        final dense = h < 170 || compact;
        final veryDense = h < 145;

        final sectionPadding =
            (h * 0.055).clamp(7.0, 12.0);

        final headerIconSize =
            (h * 0.14).clamp(18.0, 25.0);

        final headerTextSize =
            (h * 0.105).clamp(15.0, 19.0);

        final controlHeight =
            (h * 0.22).clamp(30.0, 38.0);

        final soundWidth =
            (w * 0.25).clamp(78.0, 100.0);

        final soundIconSize =
            (controlHeight * 0.55).clamp(17.0, 22.0);

        final navTextSize =
            (controlHeight * 0.36).clamp(10.5, 13.0);

        return Container(
          width: double.infinity,
          height: double.infinity,
          padding: EdgeInsets.all(sectionPadding),
          decoration: _cardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: controlHeight,
                child: Row(
                  children: [
                    Icon(
                      Icons.notifications_active_outlined,
                      color: const Color(0xFFB91C1C),
                      size: headerIconSize,
                    ),
                    SizedBox(
                      width: (w * 0.02).clamp(5.0, 8.0),
                    ),
                    Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Reminders',
                          style: TextStyle(
                            fontSize: headerTextSize,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                      ),
                    ),
                    Semantics(
                      button: true,
                      toggled: state.isAudioEnabled,
                      label: state.isAudioEnabled
                          ? 'Reminder sound on. Tap to mute.'
                          : 'Reminder sound muted. Tap to turn on and play a sample.',
                      child: SizedBox(
                        width: soundWidth,
                        height: controlHeight,
                        child: OutlinedButton.icon(
                          key: const Key(
                            'elderly_sound_toggle',
                          ),
                          onPressed: () =>
                              _toggleReminderSound(notifier),
                          icon: Icon(
                            state.isAudioEnabled
                                ? Icons.volume_up_rounded
                                : Icons.volume_off_rounded,
                            size: soundIconSize,
                          ),
                          label: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              state.isAudioEnabled
                                  ? 'Sound on'
                                  : 'Muted',
                              style: TextStyle(
                                fontSize: navTextSize,
                              ),
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                              horizontal: dense ? 6 : 9,
                              vertical: 0,
                            ),
                            minimumSize: Size.zero,
                            tapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            foregroundColor:
                                state.isAudioEnabled
                                    ? const Color(0xFF1D4ED8)
                                    : const Color(0xFF475569),
                            side: BorderSide(
                              width: dense ? 1.5 : 2,
                              color: state.isAudioEnabled
                                  ? const Color(0xFF93C5FD)
                                  : const Color(0xFFCBD5E1),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(13),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: veryDense ? 2 : 4,
              ),
              if (reminders.isEmpty)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.task_alt_rounded,
                          size:
                              (h * 0.19).clamp(24.0, 34.0),
                          color: const Color(0xFF15803D),
                        ),
                        SizedBox(
                          height: veryDense ? 2 : 5,
                        ),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'No reminders right now',
                            style: TextStyle(
                              fontSize:
                                  (h * 0.095).clamp(
                                13.0,
                                17.0,
                              ),
                              fontWeight: FontWeight.w800,
                              color:
                                  const Color(0xFF334155),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else ...[
                Expanded(
                  child: GestureDetector(
                    onHorizontalDragEnd: (details) {
                      final velocity =
                          details.primaryVelocity ?? 0;

                      if (velocity.abs() < 150) return;

                      _moveReminder(
                        velocity < 0 ? 1 : -1,
                        reminders.length,
                      );
                    },
                    child: AnimatedSwitcher(
                      duration: reduceMotion
                          ? Duration.zero
                          : const Duration(
                              milliseconds: 220,
                            ),
                      transitionBuilder:
                          (child, animation) =>
                              reduceMotion
                                  ? child
                                  : FadeTransition(
                                      opacity: animation,
                                      child:
                                          SlideTransition(
                                        position:
                                            Tween<Offset>(
                                          begin:
                                              const Offset(
                                            0.05,
                                            0,
                                          ),
                                          end:
                                              Offset.zero,
                                        ).animate(
                                          animation,
                                        ),
                                        child: child,
                                      ),
                                    ),
                      child: _buildReminderCard(
                        reminders[currentIndex],
                        notifier,
                        activeElderlyId,
                        compact: dense,
                        key: ValueKey(
                          reminders[currentIndex].id,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  height: veryDense ? 2 : 4,
                ),
                SizedBox(
                  height: controlHeight,
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed:
                              reminders.length > 1
                                  ? () =>
                                      _moveReminder(
                                        -1,
                                        reminders.length,
                                      )
                                  : null,
                          icon: Icon(
                            Icons.arrow_back_rounded,
                            size: soundIconSize,
                          ),
                          label: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              'Previous',
                              style: TextStyle(
                                fontSize: navTextSize,
                              ),
                            ),
                          ),
                          style: _carouselButtonStyle(
                            controlHeight,
                            dense,
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal:
                              (w * 0.025).clamp(
                            5.0,
                            10.0,
                          ),
                        ),
                        child: Semantics(
                          liveRegion: true,
                          label:
                              'Reminder ${currentIndex + 1} of ${reminders.length}',
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              '${currentIndex + 1} / ${reminders.length}',
                              style: TextStyle(
                                fontSize:
                                    (h * 0.085).clamp(
                                  11.0,
                                  16.0,
                                ),
                                fontWeight:
                                    FontWeight.w900,
                                color: const Color(
                                  0xFF334155,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed:
                              reminders.length > 1
                                  ? () =>
                                      _moveReminder(
                                        1,
                                        reminders.length,
                                      )
                                  : null,
                          icon: Icon(
                            Icons.arrow_forward_rounded,
                            size: soundIconSize,
                          ),
                          label: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              'Next',
                              style: TextStyle(
                                fontSize: navTextSize,
                              ),
                            ),
                          ),
                          style:
                              ElevatedButton.styleFrom(
                            padding:
                                EdgeInsets.symmetric(
                              horizontal:
                                  dense ? 6 : 10,
                            ),
                            minimumSize: Size.zero,
                            tapTargetSize:
                                MaterialTapTargetSize
                                    .shrinkWrap,
                            backgroundColor:
                                const Color(
                              0xFF075DBB,
                            ),
                            foregroundColor:
                                Colors.white,
                            disabledBackgroundColor:
                                const Color(
                              0xFFE2E8F0,
                            ),
                            disabledForegroundColor:
                                const Color(
                              0xFF64748B,
                            ),
                            shape:
                                RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(
                                16,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  ButtonStyle _carouselButtonStyle(
    double height,
    bool dense,
  ) {
    return OutlinedButton.styleFrom(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 6 : 10,
      ),
      minimumSize: Size.zero,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      foregroundColor: const Color(0xFF1D4ED8),
      side: BorderSide(
        color: const Color(0xFF93C5FD),
        width: dense ? 1.5 : 2,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
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

    return LayoutBuilder(
      key: key,
      builder: (context, constraints) {
        final h = constraints.maxHeight;
        final w = constraints.maxWidth;

        final dense = h < 110 || compact;
        final veryDense = h < 90;

        final pad =
            (h * 0.06).clamp(4.0, 8.0);

        final iconSize =
            (h * 0.20).clamp(20.0, 30.0);

        final titleSize =
            (h * 0.115).clamp(11.5, 16.0);

        final detailSize =
            (h * 0.09).clamp(9.5, 13.0);

        // Bigger responsive Mark as done button
        final actionHeight =
            (h * 0.32).clamp(40.0, 54.0);

        final actionTextSize =
            (actionHeight * 0.34).clamp(
          13.0,
          17.0,
        );

        final actionIconSize =
            (actionHeight * 0.44).clamp(
          18.0,
          24.0,
        );

        final contentGap =
            (h * 0.035).clamp(2.0, 5.0);

        final buttonGap =
            (h * 0.045).clamp(3.0, 7.0);

        return Container(
          width: double.infinity,
          height: double.infinity,
          padding: EdgeInsets.all(pad),
          decoration: BoxDecoration(
            color: isCompleted
                ? const Color(0xFFF0FDF4)
                : const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isCompleted
                  ? const Color(0xFF86EFAC)
                  : const Color(0xFF93C5FD),
              width: dense ? 1.5 : 2,
            ),
          ),
          child: Column(
            children: [
              // Reminder information
              Expanded(
                child: Row(
                  crossAxisAlignment:
                      CrossAxisAlignment.center,
                  children: [
                    Container(
                      width:
                          (iconSize * 1.45).clamp(
                        34.0,
                        46.0,
                      ),
                      height:
                          (iconSize * 1.45).clamp(
                        34.0,
                        46.0,
                      ),
                      decoration: BoxDecoration(
                        color: isCompleted
                            ? const Color(
                                0xFFDCFCE7,
                              )
                            : const Color(
                                0xFFDBEAFE,
                              ),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isCompleted
                            ? Icons.task_alt_rounded
                            : Icons.alarm_rounded,
                        size: iconSize,
                        color: isCompleted
                            ? const Color(
                                0xFF15803D,
                              )
                            : const Color(
                                0xFF1D4ED8,
                              ),
                      ),
                    ),
                    SizedBox(
                      width:
                          (w * 0.025).clamp(
                        6.0,
                        10.0,
                      ),
                    ),

                    // Reminder title and details
                    Expanded(
                      child: Column(
                        mainAxisAlignment:
                            MainAxisAlignment.center,
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            reminder.title,
                            maxLines:
                                veryDense ? 1 : 2,
                            overflow:
                                TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: titleSize,
                              height: 1.05,
                              fontWeight:
                                  FontWeight.w900,
                              color: const Color(
                                0xFF0F172A,
                              ),
                            ),
                          ),
                          SizedBox(
                            height: contentGap,
                          ),
                          Row(
                            children: [
                              Icon(
                                Icons
                                    .schedule_rounded,
                                size:
                                    (detailSize * 1.25)
                                        .clamp(
                                  12.0,
                                  16.0,
                                ),
                                color: const Color(
                                  0xFF1D4ED8,
                                ),
                              ),
                              const SizedBox(
                                width: 3,
                              ),
                              Expanded(
                                child: Text(
                                  _formatReminderDateTime(
                                    reminder.date,
                                    reminder.time,
                                  ),
                                  maxLines: 1,
                                  overflow:
                                      TextOverflow
                                          .ellipsis,
                                  style:
                                      TextStyle(
                                    fontSize:
                                        detailSize,
                                    fontWeight:
                                        FontWeight
                                            .w800,
                                    color:
                                        const Color(
                                      0xFF1E3A8A,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (reminder
                                      .dosageOrLocation
                                      ?.isNotEmpty ==
                                  true &&
                              h >= 90) ...[
                            SizedBox(
                              height: contentGap,
                            ),
                            Row(
                              children: [
                                Icon(
                                  Icons
                                      .info_outline_rounded,
                                  size:
                                      (detailSize *
                                              1.25)
                                          .clamp(
                                    12.0,
                                    16.0,
                                  ),
                                  color:
                                      const Color(
                                    0xFF475569,
                                  ),
                                ),
                                const SizedBox(
                                  width: 3,
                                ),
                                Expanded(
                                  child: Text(
                                    reminder
                                        .dosageOrLocation!,
                                    maxLines: 1,
                                    overflow:
                                        TextOverflow
                                            .ellipsis,
                                    style:
                                        TextStyle(
                                      fontSize:
                                          detailSize,
                                      fontWeight:
                                          FontWeight
                                              .w600,
                                      color:
                                          const Color(
                                        0xFF334155,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(
                height: buttonGap,
              ),

              // Bigger Mark as done button BELOW reminder information
              SizedBox(
                width: double.infinity,
                height: actionHeight,
                child: ElevatedButton.icon(
                  onPressed: isCompleted
                      ? null
                      : () =>
                          notifier.confirmMedication(
                            reminder.id,
                            elderlyId:
                                activeElderlyId,
                          ),
                  icon: Icon(
                    isCompleted
                        ? Icons
                            .check_circle_rounded
                        : Icons
                            .check_rounded,
                    size: actionIconSize,
                  ),
                  label: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      isCompleted
                          ? 'Completed'
                          : 'Mark as done',
                      maxLines: 1,
                      style: TextStyle(
                        fontSize:
                            actionTextSize,
                        fontWeight:
                            FontWeight.w900,
                      ),
                    ),
                  ),
                  style:
                      ElevatedButton.styleFrom(
                    padding:
                        EdgeInsets.symmetric(
                      horizontal:
                          dense ? 10 : 16,
                      vertical: 0,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize:
                        MaterialTapTargetSize
                            .shrinkWrap,
                    backgroundColor:
                        const Color(
                      0xFF15803D,
                    ),
                    foregroundColor:
                        Colors.white,
                    disabledBackgroundColor:
                        const Color(
                      0xFFDCFCE7,
                    ),
                    disabledForegroundColor:
                        const Color(
                      0xFF166534,
                    ),
                    elevation:
                        isCompleted ? 0 : 2,
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(
                        14,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMoodSection({
    required bool compact,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final h = constraints.maxHeight;
        final w = constraints.maxWidth;

        final dense = h < 155 || compact;
        final veryDense = h < 125;

        final padding =
            (h * 0.06).clamp(7.0, 12.0);

        final titleSize =
            (h * 0.13).clamp(15.0, 21.0);

        final gap =
            (w * 0.025).clamp(5.0, 10.0);

        return Container(
          width: double.infinity,
          height: double.infinity,
          padding: EdgeInsets.all(padding),
          decoration: _cardDecoration(
            borderColor:
                const Color(0xFFBFDBFE),
          ),
          child: Column(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  'How are you feeling?',
                  style: TextStyle(
                    fontSize: titleSize,
                    fontWeight:
                        FontWeight.w900,
                    color:
                        const Color(
                      0xFF0F172A,
                    ),
                  ),
                ),
              ),
              SizedBox(
                height: veryDense
                    ? 3
                    : (h * 0.045).clamp(
                        5.0,
                        8.0,
                      ),
              ),
              Expanded(
                child: Row(
                  crossAxisAlignment:
                      CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child:
                          _buildFeelingButton(
                        icon: Icons
                            .sentiment_very_satisfied_rounded,
                        label: 'Good',
                        moodValue: 'Happy',
                        compact: dense,
                        background:
                            const Color(
                          0xFFF0FDF4,
                        ),
                        foreground:
                            const Color(
                          0xFF166534,
                        ),
                      ),
                    ),
                    SizedBox(width: gap),
                    Expanded(
                      child:
                          _buildFeelingButton(
                        icon: Icons
                            .sentiment_neutral_rounded,
                        label: 'Okay',
                        moodValue: 'Neutral',
                        compact: dense,
                        background:
                            const Color(
                          0xFFFEFCE8,
                        ),
                        foreground:
                            const Color(
                          0xFF854D0E,
                        ),
                      ),
                    ),
                    SizedBox(width: gap),
                    Expanded(
                      child:
                          _buildFeelingButton(
                        icon: Icons
                            .sentiment_dissatisfied_rounded,
                        label: 'Not well',
                        moodValue: 'Sad',
                        compact: dense,
                        background:
                            const Color(
                          0xFFFEF2F2,
                        ),
                        foreground:
                            const Color(
                          0xFF991B1B,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFeelingButton({
    required IconData icon,
    required String label,
    required String moodValue,
    required bool compact,
    required Color background,
    required Color foreground,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final h = constraints.maxHeight;
        final w = constraints.maxWidth;

        final verySmall = h < 55;

        final iconSize =
            (h * 0.40).clamp(18.0, 28.0);

        final textSize =
            (h * 0.20).clamp(10.0, 14.0);

        final radius =
            (h * 0.20).clamp(10.0, 16.0);

        final verticalPadding =
            (h * 0.06).clamp(2.0, 7.0);

        final horizontalPadding =
            (w * 0.04).clamp(2.0, 5.0);

        return Semantics(
          button: true,
          label: 'I feel $label',
          child: Material(
            color: background,
            borderRadius:
                BorderRadius.circular(radius),
            child: InkWell(
              onTap: () =>
                  _logMood(moodValue),
              borderRadius:
                  BorderRadius.circular(radius),
              child: Container(
                width: double.infinity,
                height: double.infinity,
                padding:
                    EdgeInsets.symmetric(
                  vertical: verticalPadding,
                  horizontal:
                      horizontalPadding,
                ),
                decoration: BoxDecoration(
                  borderRadius:
                      BorderRadius.circular(
                    radius,
                  ),
                  border: Border.all(
                    color: foreground
                        .withOpacity(0.35),
                    width:
                        compact ? 1.5 : 2,
                  ),
                ),
                child: Column(
                  mainAxisAlignment:
                      MainAxisAlignment.center,
                  children: [
                    Icon(
                      icon,
                      size: iconSize,
                      color: foreground,
                    ),
                    if (!verySmall) ...[
                      SizedBox(
                        height:
                            (h * 0.04).clamp(
                          1.0,
                          3.0,
                        ),
                      ),
                      FittedBox(
                        fit:
                            BoxFit.scaleDown,
                        child: Text(
                          label,
                          textAlign:
                              TextAlign.center,
                          maxLines: 1,
                          style: TextStyle(
                            fontSize:
                                textSize,
                            fontWeight:
                                FontWeight
                                    .w900,
                            color:
                                foreground,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  BoxDecoration _cardDecoration({
    Color borderColor =
        const Color(0xFFE2E8F0),
  }) {
    return BoxDecoration(
      color: Colors.white,
      borderRadius:
          BorderRadius.circular(24),
      border: Border.all(
        color: borderColor,
        width: 2,
      ),
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