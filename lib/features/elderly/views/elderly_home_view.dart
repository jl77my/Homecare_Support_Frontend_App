import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/enums.dart';
import '../../../core/models/models.dart';
import '../providers/elderly_provider.dart';

class ElderlyView extends ConsumerStatefulWidget {
  const ElderlyView({super.key});

  @override
  ConsumerState<ElderlyView> createState() => _ElderlyViewState();
}

class _ElderlyViewState extends ConsumerState<ElderlyView> {
  ReminderCategory? _selectedCategoryFilter;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(elderlyProvider.notifier).fetchReminders());
  }

  void _logMood(String moodLabel) {
    ref.read(elderlyProvider.notifier).logMood(moodLabel);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Logged feeling as $moodLabel. Caregivers notified!'),
        duration: const Duration(seconds: 2),
        backgroundColor: const Color(0xFF0F172A),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(elderlyProvider);
    final notifier = ref.read(elderlyProvider.notifier);

    final reminders = _selectedCategoryFilter == null
        ? state.reminders
        : state.reminders.where((r) => r.category == _selectedCategoryFilter).toList();

    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        // SOS Button
        GestureDetector(
          onTap: () {
            if (state.isSosActive) {
              notifier.resolveSOS();
            } else {
              notifier.triggerSOS();
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: state.isSosActive ? Colors.black : const Color(0xFFDC2626),
              borderRadius: BorderRadius.circular(44),
              border: Border.all(
                color: state.isSosActive ? Colors.red : Colors.white.withOpacity(0.3),
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: (state.isSosActive ? Colors.red : const Color(0xFFDC2626)).withOpacity(0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    state.isSosActive ? Icons.check_circle_outline : Icons.warning_amber_rounded,
                    size: 64,
                    color: state.isSosActive ? Colors.greenAccent : Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  state.isSosActive ? 'HELP IS ON THE WAY' : 'EMERGENCY HELP',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    state.isSosActive
                        ? 'Stay calm, caregivers & family notified'
                        : 'TAP TO ALARM CAREGIVERS & FAMILY',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Reminders Section for Senior
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(36),
            border: Border.all(color: const Color(0xFFE2E8F0), width: 2),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0F000000),
                blurRadius: 16,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.notifications_active, color: Color(0xFFEF4444), size: 26),
                      SizedBox(width: 8),
                      Text(
                        'Your Reminders',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                  InkWell(
                    onTap: notifier.toggleAudio,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: state.isAudioEnabled ? const Color(0xFFEFF6FF) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: state.isAudioEnabled ? const Color(0xFFBFDBFE) : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            state.isAudioEnabled ? Icons.volume_up : Icons.volume_off,
                            size: 16,
                            color: state.isAudioEnabled ? const Color(0xFF1D4ED8) : const Color(0xFF94A3B8),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            state.isAudioEnabled ? 'Sound ON' : 'Muted',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: state.isAudioEnabled ? const Color(0xFF1D4ED8) : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Category Pills
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('All Reminders', null),
                    const SizedBox(width: 8),
                    _buildFilterChip('💊 Pills', ReminderCategory.medication),
                    const SizedBox(width: 8),
                    _buildFilterChip('📅 Doctors', ReminderCategory.appointment),
                    const SizedBox(width: 8),
                    _buildFilterChip('🏃 Activities', ReminderCategory.careActivity),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              if (state.isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (reminders.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.check_circle_outline, size: 48, color: Color(0xFFCBD5E1)),
                        SizedBox(height: 8),
                        Text(
                          'No reminders in this category!',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: reminders.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    final rem = reminders[index];
                    return _buildReminderCard(rem, notifier);
                  },
                ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Mood / Feeling Logger
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(36),
            border: Border.all(color: const Color(0xFFBFDBFE), width: 2),
            boxShadow: const [
              BoxShadow(
                color: Color(0x08000000),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              const Text(
                'How are you feeling right now?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildFeelingButton(
                      emoji: '😊',
                      label: 'FEEL GREAT',
                      moodValue: 'Happy', // Standardized payload
                      bgColor: const Color(0xFFF0FDF4),
                      borderColor: const Color(0xFFBBF7D0),
                      textColor: const Color(0xFF166534),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildFeelingButton(
                      emoji: '😐',
                      label: 'OKAY',
                      moodValue: 'Neutral', // Standardized payload
                      bgColor: const Color(0xFFFEFCE8),
                      borderColor: const Color(0xFFFEF08A),
                      textColor: const Color(0xFF854D0E),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildFeelingButton(
                      emoji: '😴',
                      label: 'TIRED',
                      moodValue: 'Sad', // Standardized payload
                      bgColor: const Color(0xFFFEF2F2),
                      borderColor: const Color(0xFFFECACA),
                      textColor: const Color(0xFF991B1B),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, ReminderCategory? category) {
    final isSelected = _selectedCategoryFilter == category;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w900,
          color: isSelected ? Colors.white : const Color(0xFF334155),
        ),
      ),
      selected: isSelected,
      onSelected: (_) => setState(() => _selectedCategoryFilter = category),
      selectedColor: const Color(0xFF0F172A),
      backgroundColor: const Color(0xFFF1F5F9),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      showCheckmark: false,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    );
  }

  Widget _buildReminderCard(Reminder rem, ElderlyNotifier notifier) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: rem.isCompleted ? const Color(0xFFF8FAFC) : Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: rem.isCompleted ? const Color(0xFFE2E8F0) : const Color(0xFF60A5FA),
          width: rem.isCompleted ? 1.5 : 2.5,
        ),
        boxShadow: rem.isCompleted
            ? null
            : [
                BoxShadow(
                  color: const Color(0xFF3B82F6).withOpacity(0.12),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _getCategoryColor(rem.category).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _getCategoryColor(rem.category).withOpacity(0.3)),
                ),
                child: Text(
                  '${rem.category.emoji} ${rem.category.label.toUpperCase()}',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: _getCategoryColor(rem.category),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.access_time, size: 14, color: Color(0xFF2563EB)),
                    const SizedBox(width: 4),
                    Text(
                      rem.time,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          Text(
            rem.title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: rem.isCompleted ? const Color(0xFF94A3B8) : const Color(0xFF0F172A),
              decoration: rem.isCompleted ? TextDecoration.lineThrough : null,
            ),
          ),

          if (rem.dosageOrLocation != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFF1F5F9)),
              ),
              child: Row(
                children: [
                  Icon(
                    rem.category == ReminderCategory.appointment ? Icons.location_on : Icons.medication,
                    size: 16,
                    color: rem.category == ReminderCategory.appointment ? Colors.blue : Colors.red,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      rem.dosageOrLocation!,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
                    ),
                  ),
                ],
              ),
            ),
          ],

          if (rem.notes != null) ...[
            const SizedBox(height: 6),
            Text(
              '💡 ${rem.notes}',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
            ),
          ],

          const SizedBox(height: 14),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => notifier.confirmMedication(rem.id),
              icon: Icon(
                rem.isCompleted ? Icons.check_circle : Icons.check,
                size: 24,
              ),
              label: Text(
                rem.isCompleted ? 'DONE AT ${rem.completedAt ?? "TODAY"}' : 'MARK COMPLETED NOW',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: rem.isCompleted ? const Color(0xFFCBD5E1) : const Color(0xFF22C55E),
                foregroundColor: rem.isCompleted ? const Color(0xFF334155) : Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(ReminderCategory cat) {
    switch (cat) {
      case ReminderCategory.medication:
        return const Color(0xFFEF4444);
      case ReminderCategory.appointment:
        return const Color(0xFF2563EB);
      case ReminderCategory.careActivity:
        return const Color(0xFF10B981);
    }
  }

    Widget _buildFeelingButton({
    required String emoji,
    required String label,
    required String moodValue,
    required Color bgColor,
    required Color borderColor,
    required Color textColor,
  }) {
    return InkWell(
      onTap: () => _logMood(moodValue),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor, width: 1.5),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 32)),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: textColor),
            ),
          ],
        ),
      ),
    );
  }
}