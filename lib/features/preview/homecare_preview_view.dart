import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class HomeCarePreviewView extends StatefulWidget {
  const HomeCarePreviewView({super.key});

  @override
  State<HomeCarePreviewView> createState() => _HomeCarePreviewViewState();
}

class _HomeCarePreviewViewState extends State<HomeCarePreviewView> {
  String _role = 'caregiver';

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 72,
        title: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: scheme.primary,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(Icons.favorite_rounded,
                  color: scheme.onPrimary, size: 23),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('HomeCare', style: Theme.of(context).textTheme.titleLarge),
                Text(
                  'Interactive UI preview',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: CircleAvatar(
              backgroundColor: scheme.primaryContainer,
              foregroundColor: scheme.onPrimaryContainer,
              child: const Text('JL',
                  style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final gutter = constraints.maxWidth >= 900 ? 40.0 : 16.0;
            return ListView(
              padding: EdgeInsets.fromLTRB(gutter, 16, gutter, 120),
              children: [
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    SizedBox(
                      width: constraints.maxWidth < 680
                          ? constraints.maxWidth
                          : constraints.maxWidth - 330,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _role == 'senior'
                                ? 'Good morning, Margaret'
                                : 'Good morning, Jia Li',
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _role == 'senior'
                                ? 'Your care circle is connected.'
                                : 'Here is today’s care overview.',
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    ),
                    SegmentedButton<String>(
                        showSelectedIcon: false,
                        segments: const [
                          ButtonSegment(
                            value: 'caregiver',
                            icon: Icon(Icons.medical_services_outlined),
                            label: Text('Caregiver'),
                          ),
                          ButtonSegment(
                            value: 'senior',
                            icon: Icon(Icons.elderly_rounded),
                            label: Text('Senior'),
                          ),
                        ],
                        selected: {_role},
                        onSelectionChanged: (selection) =>
                            setState(() => _role = selection.first),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                AnimatedSwitcher(
                  duration: MediaQuery.disableAnimationsOf(context)
                      ? Duration.zero
                      : const Duration(milliseconds: 220),
                  child: _role == 'senior'
                      ? const _SeniorPreview(key: ValueKey('senior'))
                      : const _CaregiverPreview(key: ValueKey('caregiver')),
                ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: _role == 'caregiver'
          ? FloatingActionButton.extended(
              onPressed: () {},
              icon: const Icon(Icons.auto_awesome_outlined),
              label: const Text('Ask Care Agent'),
            )
          : null,
      bottomNavigationBar: _role == 'caregiver'
          ? const _PreviewNavigation()
          : null,
    );
  }
}

class _CaregiverPreview extends StatelessWidget {
  const _CaregiverPreview({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _PatientSelector(scheme: scheme),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final cards = [
              _MetricCard(
                icon: Icons.favorite_outline_rounded,
                label: 'Heart rate',
                value: '72',
                unit: 'BPM',
                note: 'Within normal range',
                color: AppTheme.primaryRed,
              ),
              _MetricCard(
                icon: Icons.speed_outlined,
                label: 'Blood pressure',
                value: '120/80',
                unit: 'mmHg',
                note: 'Recorded 9:10 AM',
                color: AppTheme.primaryDark,
              ),
              _MetricCard(
                icon: Icons.water_drop_outlined,
                label: 'Blood glucose',
                value: '95',
                unit: 'mg/dL',
                note: 'Stable this week',
                color: AppTheme.primaryGreen,
              ),
            ];
            if (constraints.maxWidth < 760) {
              return Column(
                children: [
                  for (var i = 0; i < cards.length; i++) ...[
                    cards[i],
                    if (i < cards.length - 1) const SizedBox(height: 12),
                  ],
                ],
              );
            }
            return Row(
              children: [
                for (var i = 0; i < cards.length; i++) ...[
                  Expanded(child: cards[i]),
                  if (i < cards.length - 1) const SizedBox(width: 12),
                ],
              ],
            );
          },
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final insight = _InsightCard(scheme: scheme);
            final schedule = _ScheduleCard(scheme: scheme);
            if (constraints.maxWidth < 760) {
              return Column(
                children: [insight, const SizedBox(height: 16), schedule],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 6, child: insight),
                const SizedBox(width: 16),
                Expanded(flex: 5, child: schedule),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _PatientSelector extends StatelessWidget {
  const _PatientSelector({required this.scheme});
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: scheme.primaryContainer,
              foregroundColor: scheme.onPrimaryContainer,
              child: const Text('MT',
                  style: TextStyle(fontWeight: FontWeight.w800)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Margaret Tan',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(Icons.circle, size: 9, color: scheme.secondary),
                      const SizedBox(width: 6),
                      Text('Connected · Synced just now',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                              )),
                    ],
                  ),
                ],
              ),
            ),
            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.swap_horiz_rounded),
              label: const Text('Switch'),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
    required this.note,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final String unit;
  final String note;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: .1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: color),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(label,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: scheme.onSurfaceVariant,
                          )),
                ),
              ],
            ),
            const SizedBox(height: 18),
            RichText(
              text: TextSpan(
                style: Theme.of(context).textTheme.headlineMedium,
                children: [
                  TextSpan(text: value),
                  TextSpan(
                    text: '  $unit',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text(note,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    )),
          ],
        ),
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({required this.scheme});
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [scheme.primary, AppTheme.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .14),
              borderRadius: BorderRadius.circular(99),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 16),
                SizedBox(width: 6),
                Text('HEALTH INSIGHT',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: .7,
                    )),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const Text('Vitals look stable',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w800,
              )),
          const SizedBox(height: 8),
          const Text(
            'No unusual pattern was detected across the latest records. Continue the current monitoring routine.',
            style: TextStyle(color: Color(0xFFE1FAFC), height: 1.5),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppTheme.primaryDark,
            ),
            onPressed: () {},
            icon: const Icon(Icons.insights_rounded),
            label: const Text('View health trend'),
          ),
        ],
      ),
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  const _ScheduleCard({required this.scheme});
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.today_outlined, color: scheme.primary),
                const SizedBox(width: 8),
                Text('Next up', style: Theme.of(context).textTheme.titleLarge),
                const Spacer(),
                TextButton(onPressed: () {}, child: const Text('View all')),
              ],
            ),
            const SizedBox(height: 8),
            const _TimelineItem(
              time: '10:30 AM',
              title: 'Morning medication',
              subtitle: 'Amlodipine · 5 mg',
              color: AppTheme.primaryBlue,
            ),
            const _TimelineItem(
              time: '1:00 PM',
              title: 'Lunch & hydration',
              subtitle: 'Care task · Assigned to you',
              color: AppTheme.primaryGreen,
            ),
            const _TimelineItem(
              time: '4:30 PM',
              title: 'Blood pressure check',
              subtitle: 'Daily health record',
              color: AppTheme.primaryAmber,
              isLast: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  const _TimelineItem({
    required this.time,
    required this.title,
    required this.subtitle,
    required this.color,
    this.isLast = false,
  });

  final String time;
  final String title;
  final String subtitle;
  final Color color;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 74,
            child: Text(time,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    )),
          ),
          Column(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              if (!isLast)
                Expanded(child: Container(width: 2, color: scheme.outlineVariant)),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 3),
                  Text(subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          )),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SeniorPreview extends StatelessWidget {
  const _SeniorPreview({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Material(
          color: AppTheme.primaryRed,
          borderRadius: BorderRadius.circular(26),
          child: InkWell(
            onTap: () {},
            borderRadius: BorderRadius.circular(26),
            child: const Padding(
              padding: EdgeInsets.all(22),
              child: Row(
                children: [
                  SizedBox(
                    width: 68,
                    height: 68,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Color(0x26FFFFFF),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.sos_rounded,
                          color: Colors.white, size: 46),
                    ),
                  ),
                  SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Emergency help',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 27,
                              fontWeight: FontWeight.w900,
                            )),
                        SizedBox(height: 4),
                        Text('Tap here to alert your care team.',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                            )),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.notifications_active_outlined,
                        color: scheme.primary, size: 30),
                    const SizedBox(width: 10),
                    Text('Your next reminder',
                        style: Theme.of(context).textTheme.titleLarge),
                  ],
                ),
                const SizedBox(height: 22),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          color: scheme.surface,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Icon(Icons.medication_outlined,
                            color: scheme.primary, size: 30),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Take Amlodipine',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(fontSize: 22)),
                            const SizedBox(height: 4),
                            const Text('5 mg · Today at 10:30 AM',
                                style: TextStyle(fontSize: 17)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.check_circle_outline_rounded),
                    label: const Text('I have taken it',
                        style: TextStyle(fontSize: 18)),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('How are you feeling?',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _MoodButton(
                        icon: Icons.sentiment_satisfied_alt_rounded,
                        label: 'Good',
                        color: AppTheme.primaryGreen,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _MoodButton(
                        icon: Icons.sentiment_neutral_rounded,
                        label: 'Okay',
                        color: AppTheme.primaryAmber,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _MoodButton(
                        icon: Icons.sentiment_dissatisfied_rounded,
                        label: 'Unwell',
                        color: AppTheme.primaryRed,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MoodButton extends StatelessWidget {
  const _MoodButton({required this.icon, required this.label, required this.color});
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: () {},
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        minimumSize: const Size(48, 78),
        side: BorderSide(color: color.withValues(alpha: .35)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [Icon(icon, size: 30), const SizedBox(height: 5), Text(label)],
      ),
    );
  }
}

class _PreviewNavigation extends StatelessWidget {
  const _PreviewNavigation();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(top: BorderSide(color: scheme.outlineVariant)),
      ),
      child: SafeArea(
        top: false,
        child: NavigationBar(
          selectedIndex: 0,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.space_dashboard_outlined),
              selectedIcon: Icon(Icons.space_dashboard_rounded),
              label: 'Overview',
            ),
            NavigationDestination(
                icon: Icon(Icons.description_outlined), label: 'Reports'),
            NavigationDestination(
                icon: Icon(Icons.notifications_none_rounded),
                label: 'Reminders'),
            NavigationDestination(
                icon: Icon(Icons.task_alt_outlined), label: 'Tasks'),
            NavigationDestination(
                icon: Icon(Icons.forum_outlined), label: 'Connect'),
          ],
        ),
      ),
    );
  }
}
