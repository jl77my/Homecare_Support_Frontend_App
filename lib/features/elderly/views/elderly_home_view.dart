import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/models/enums.dart';
import '../../../core/models/models.dart';
import '../../auth/providers/auth_provider.dart';
import '../../caregiver/views/profile_view.dart';
import '../providers/elderly_provider.dart';
import '../widgets/pairing_code_modal.dart';

String _formatReminderDateTime(String dateStr, String timeStr) {
  try {
    DateTime parsedDate;
    if (dateStr == 'Today' || dateStr.isEmpty) {
      parsedDate = DateTime.now();
    } else {
      parsedDate = DateFormat('yyyy-MM-dd').parse(dateStr);
    }

    DateTime parsedTime;
    try {
      parsedTime = DateFormat('HH:mm:ss').parse(timeStr);
    } catch (_) {
      parsedTime = DateFormat('hh:mm a').parse(timeStr);
    }

    final combined = DateTime(
      parsedDate.year, parsedDate.month, parsedDate.day,
      parsedTime.hour, parsedTime.minute,
    );

    return DateFormat('MMM dd, yyyy - hh:mm a').format(combined);
  } catch (e) {
    return '$dateStr - $timeStr';
  }
}

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
    Future.microtask(() {
      ref.read(elderlyProvider.notifier).fetchReminders();
    });
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

  void _showPairingCodeModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
      ),
      builder: (context) => const PairingCodeModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(elderlyProvider);
    final notifier = ref.read(elderlyProvider.notifier);
    final authUser = ref.watch(authProvider).user;
    final activeElderlyId = authUser?.id ?? '';

    final reminders = _selectedCategoryFilter == null
        ? state.reminders
        : state.reminders.where((r) => r.category == _selectedCategoryFilter).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'HomeCare Senior',
          style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w900),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle, size: 30, color: Color(0xFF2563EB)),
            tooltip: 'View Profile',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const ProfileView()),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.isLinked == false
              ? _buildUnlinkedOnboardingView(context)
              : _buildActiveDashboardView(state, notifier, reminders, activeElderlyId),
    );
  }

  Widget _buildUnlinkedOnboardingView(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Container(
          padding: const EdgeInsets.all(28),
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
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFBFDBFE), width: 2),
                ),
                child: const Icon(Icons.qr_code_2, size: 64, color: Color(0xFF2563EB)),
              ),
              const SizedBox(height: 20),
              const Text(
                'Welcome to HomeCare',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 8),
              const Text(
                'Generate an invitation code below to share with your caregiver or family members so they can connect with your account.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Color(0xFF64748B), height: 1.5),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showPairingCodeModal(context),
                  icon: const Icon(Icons.key, size: 22),
                  label: const Text('GENERATE INVITATION CODE', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActiveDashboardView(ElderlyState state, ElderlyNotifier notifier, List<Reminder> reminders, String activeElderlyId) {
    return ListView(
      padding: const EdgeInsets.all(16).copyWith(bottom: 32),
      children: [
        // SOS Emergency Button
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
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('All Reminders', null),
                    const SizedBox(width: 8),
                    _buildFilterChip('💊 Pills', ReminderCategory.medication),
                    const SizedBox(width: 8),
                    _buildFilterChip('🩺 Doctors', ReminderCategory.appointment),
                    const SizedBox(width: 8),
                    _buildFilterChip('🧘 Activities', ReminderCategory.careActivity),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (reminders.isEmpty)
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
                    return _buildReminderCard(rem, notifier, activeElderlyId);
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
                      emoji: '😁',
                      label: 'FEEL GREAT',
                      moodValue: 'Happy',
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
                      moodValue: 'Neutral',
                      bgColor: const Color(0xFFFEFCE8),
                      borderColor: const Color(0xFFFEF08A),
                      textColor: const Color(0xFF854D0E),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildFeelingButton(
                      emoji: '😔',
                      label: 'TIRED',
                      moodValue: 'Sad',
                      bgColor: const Color(0xFFFEF2F2),
                      borderColor: const Color(0xFFFECACA),
                      textColor: const Color(0xFF991B1B),
                    ),
                  ),
                ],
              ),
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

  Widget _buildReminderCard(Reminder rem, ElderlyNotifier notifier, String activeElderlyId) {
    final formattedDateTime = _formatReminderDateTime(rem.date, rem.time);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: rem.isCompleted ? const Color(0xFFF8FAFC) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: rem.isCompleted ? const Color(0xFFE2E8F0) : const Color(0xFF60A5FA),
          width: rem.isCompleted ? 1.5 : 2.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            rem.category.name.toLowerCase(),
            style: const TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            '🗓️ $formattedDateTime',
            style: const TextStyle(color: Color(0xFF2563EB), fontSize: 14, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(
            rem.title,
            style: TextStyle(
              fontSize: 16, 
              fontWeight: FontWeight.bold, 
              color: rem.isCompleted ? const Color(0xFF94A3B8) : const Color(0xFF0F172A), 
              decoration: rem.isCompleted ? TextDecoration.lineThrough : null
            ),
          ),
          if (rem.dosageOrLocation != null && rem.dosageOrLocation!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(rem.dosageOrLocation!, style: const TextStyle(fontSize: 14, color: Color(0xFF334155))),
          ],
          if (rem.notes != null && rem.notes!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text('Note: ${rem.notes}', style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), fontStyle: FontStyle.italic)),
          ],
          const SizedBox(height: 8),
          Text('Added by: ${rem.createdBy ?? "Unknown"}', style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
          Text('Freq: ${rem.frequency.name}', style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
          const SizedBox(height: 12),
          
          if (!rem.isCompleted)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => notifier.confirmMedication(rem.id, elderlyId: activeElderlyId),
                icon: const Icon(Icons.check, size: 24),
                label: const Text(
                  'MARK COMPLETED NOW',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF22C55E),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                ),
              ),
            )
          else
             SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: null,
                icon: const Icon(Icons.check_circle, size: 24),
                label: Text(
                  'DONE AT ${rem.completedAt ?? "TODAY"}',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
                ),
                style: ElevatedButton.styleFrom(
                  disabledBackgroundColor: const Color(0xFFCBD5E1),
                  disabledForegroundColor: const Color(0xFF334155),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                ),
              ),
            ),
        ],
      ),
    );
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