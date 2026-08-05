import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/enums.dart';
import '../../../core/models/models.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/elderly_provider.dart';

class RemindersView extends ConsumerStatefulWidget {
  const RemindersView({super.key});

  @override
  ConsumerState<RemindersView> createState() => _RemindersViewState();
}

class _RemindersViewState extends ConsumerState<RemindersView> {
  ReminderCategory? _categoryFilter;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(elderlyProvider.notifier).fetchReminders());
  }

  void _showAddReminderModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _AddReminderModal(),
    );
  }

  void _triggerPushAlert(Reminder rem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('⚡ Instant push alert sent to Senior: "${rem.title}" at ${rem.time}'),
        backgroundColor: const Color(0xFF2563EB),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final elderlyState = ref.watch(elderlyProvider);
    final elderlyNotifier = ref.read(elderlyProvider.notifier);

    final filteredReminders = _categoryFilter == null
        ? elderlyState.reminders
        : elderlyState.reminders.where((r) => r.category == _categoryFilter).toList();

    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: const Color(0xFFF1F5F9)),
            boxShadow: const [
              BoxShadow(color: Color(0x0A000000), blurRadius: 12, offset: Offset(0, 4)),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Care Reminders',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Schedule medications, doctor visits & activities',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade600),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: _showAddReminderModal,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('NEW', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Category Filter Pills
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildCategoryPill('All (${elderlyState.reminders.length})', null),
              const SizedBox(width: 8),
              _buildCategoryPill('💊 Medications', ReminderCategory.medication),
              const SizedBox(width: 8),
              _buildCategoryPill('📅 Appointments', ReminderCategory.appointment),
              const SizedBox(width: 8),
              _buildCategoryPill('🏃 Activities', ReminderCategory.careActivity),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // List of Reminders
        if (elderlyState.isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (filteredReminders.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.alarm_off, size: 54, color: Color(0xFFCBD5E1)),
                  SizedBox(height: 10),
                  Text('No reminders found', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                ],
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filteredReminders.length,
            separatorBuilder: (_, __) => const SizedBox(height: 14),
            itemBuilder: (context, index) {
              final rem = filteredReminders[index];
              return _buildReminderItem(rem, elderlyNotifier);
            },
          ),
      ],
    );
  }

  Widget _buildCategoryPill(String label, ReminderCategory? cat) {
    final isSelected = _categoryFilter == cat;
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
      onSelected: (_) => setState(() => _categoryFilter = cat),
      selectedColor: const Color(0xFF0F172A),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: isSelected ? Colors.transparent : const Color(0xFFE2E8F0)),
      ),
      showCheckmark: false,
    );
  }

  Widget _buildReminderItem(Reminder rem, ElderlyNotifier notifier) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: rem.isCompleted ? const Color(0xFFF8FAFC) : Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: rem.isCompleted ? const Color(0xFFF1F5F9) : const Color(0xFFE2E8F0)),
        boxShadow: rem.isCompleted
            ? null
            : [
                const BoxShadow(color: Color(0x08000000), blurRadius: 10, offset: Offset(0, 4)),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Checkbox(
                value: rem.isCompleted,
                onChanged: (_) => notifier.confirmMedication(rem.id),
                activeColor: const Color(0xFF10B981),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getCategoryColor(rem.category).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${rem.category.emoji} ${rem.category.label}',
                            style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: _getCategoryColor(rem.category)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${rem.time} • ${rem.frequency.label}',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      rem.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: rem.isCompleted ? const Color(0xFF94A3B8) : const Color(0xFF0F172A),
                        decoration: rem.isCompleted ? TextDecoration.lineThrough : null,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (rem.dosageOrLocation != null) ...[
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(left: 48),
              child: Text(
                '📍 ${rem.dosageOrLocation}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
              ),
            ),
          ],

          if (rem.notes != null) ...[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 48),
              child: Text(
                '💡 ${rem.notes}',
                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
              ),
            ),
          ],

          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 48),
                child: Text(
                  'Created by ${rem.createdBy ?? "Caregiver"}',
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8)),
                ),
              ),
              TextButton.icon(
                onPressed: () => _triggerPushAlert(rem),
                icon: const Icon(Icons.notifications_active_outlined, size: 14),
                label: const Text('Push Alert', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
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
}

class _AddReminderModal extends ConsumerStatefulWidget {
  const _AddReminderModal();

  @override
  ConsumerState<_AddReminderModal> createState() => _AddReminderModalState();
}

class _AddReminderModalState extends ConsumerState<_AddReminderModal> {
  final _titleController = TextEditingController();
  final _timeController = TextEditingController(text: '09:00 AM');
  final _dosageController = TextEditingController();
  final _notesController = TextEditingController();

  ReminderCategory _category = ReminderCategory.medication;
  ReminderFrequency _frequency = ReminderFrequency.daily;

  @override
  void dispose() {
    _titleController.dispose();
    _timeController.dispose();
    _dosageController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a reminder title.')),
      );
      return;
    }

    final success = await ref.read(elderlyProvider.notifier).confirmMedication(title);

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('New care reminder created & synchronized!'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: 24,
        left: 24,
        right: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Add New Reminder',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Reminder Title',
                hintText: 'e.g. Take Blood Pressure Pill',
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<ReminderCategory>(
                    value: _category,
                    items: ReminderCategory.values.map((cat) {
                      return DropdownMenuItem(value: cat, child: Text('${cat.emoji} ${cat.label}'));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _category = val);
                    },
                    decoration: const InputDecoration(labelText: 'Category'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _timeController,
                    decoration: const InputDecoration(
                      labelText: 'Time',
                      hintText: '09:00 AM',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<ReminderFrequency>(
              value: _frequency,
              items: ReminderFrequency.values.map((freq) {
                return DropdownMenuItem(value: freq, child: Text('Frequency: ${freq.label}'));
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _frequency = val);
              },
              decoration: const InputDecoration(labelText: 'Frequency'),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _dosageController,
              decoration: const InputDecoration(
                labelText: 'Dosage or Location (Optional)',
                hintText: 'e.g. 1 Tablet with warm water',
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Special Instructions / Notes',
                hintText: 'e.g. Take strictly before breakfast',
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: const Text('CREATE REMINDER NOW', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.5)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}