import 'package:flutter/material.dart';  
import 'package:flutter_riverpod/flutter_riverpod.dart';  
import 'package:intl/intl.dart';  
import '../../../core/models/enums.dart';  
import '../../../core/models/models.dart';  
import '../../auth/providers/auth_provider.dart';  
import '../../caregiver/providers/caregiver_provider.dart';  
import '../../family/providers/family_provider.dart';  
import '../../family/views/family_pairing_view.dart';  
import '../../caregiver/views/pairing_view.dart';  
import '../../caregiver/widgets/patient_selector_bar.dart';  
import '../providers/elderly_provider.dart';  

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
    Future.microtask(() {              
      final authUser = ref.read(authProvider).user;              
      final isFamily = authUser?.role.toLowerCase() == 'family';              
      final isCaregiver = authUser?.role.toLowerCase() == 'caregiver';                     
      final activeId = isFamily                       
        ? ref.read(familyDashboardProvider).selectedElderlyId                       
        : (isCaregiver ? ref.read(caregiverProvider).activeElderlyId : authUser?.id ?? '');                                
      ref.read(elderlyProvider.notifier).fetchReminders(elderlyId: activeId);          
    });      
  }

  void _showAddReminderModal(String activeElderlyId, {Reminder? existingReminder}) {          
    if (activeElderlyId.isEmpty) {              
      ScaffoldMessenger.of(context).showSnackBar(                  
        const SnackBar(content: Text('Please select a senior patient first.')),              
      );              
      return;          
    }          
    showModalBottomSheet(              
      context: context,              
      isScrollControlled: true,              
      backgroundColor: Colors.transparent,              
      builder: (context) => _AddReminderModal(patientId: activeElderlyId, existingReminder: existingReminder),          
    );      
  }

  @override      
  Widget build(BuildContext context) {          
    final authUser = ref.watch(authProvider).user;          
    final isFamily = authUser?.role.toLowerCase() == 'family';          
    final isCaregiver = authUser?.role.toLowerCase() == 'caregiver';          
    final familyState = ref.watch(familyDashboardProvider);          
    final caregiverState = ref.watch(caregiverProvider);          
    final activeElderlyId = isFamily                   
      ? familyState.selectedElderlyId                   
      : (isCaregiver ? caregiverState.activeElderlyId : authUser?.id ?? '');               
    final assignedSeniors = isFamily                   
      ? familyState.linkedSeniors                   
      : (isCaregiver ? caregiverState.assignedSeniors : <Map<String, String>>[]);          
    final elderlyState = ref.watch(elderlyProvider);          
    final elderlyNotifier = ref.read(elderlyProvider.notifier);          
    final filteredReminders = _categoryFilter == null                  
      ? elderlyState.reminders                  
      : elderlyState.reminders.where((r) => r.category == _categoryFilter).toList();                   
    
    return ListView(              
      padding: const EdgeInsets.only(bottom: 32),              
      children: [                  
        if (!isFamily && !isCaregiver) const SizedBox.shrink() else                       
          PatientSelectorBar(                          
            assignedSeniors: assignedSeniors,                          
            selectedElderlyId: activeElderlyId,                          
            onElderlySelected: (newElderlyId) {                              
              if (isFamily) {                                  
                ref.read(familyDashboardProvider.notifier).switchElderlyContext(newElderlyId);                              
              } else {                                  
                ref.read(caregiverProvider.notifier).switchElderlyContext(newElderlyId);                              
              }                              
              ref.read(elderlyProvider.notifier).fetchReminders(elderlyId: newElderlyId);                          
            },                          
            onPairNewElderly: () {                              
              Navigator.of(context).push(                                  
                MaterialPageRoute(builder: (context) => isFamily ? const FamilyPairingView() : const PairingView()),                              
              );                          
            },                      
          ),                           
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
              if (!isFamily)                  
                ElevatedButton.icon(                                      
                  onPressed: () => _showAddReminderModal(activeElderlyId),                                      
                  icon: const Icon(Icons.add, size: 18),                                      
                  label: const Text('NEW', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900)),                                      
                  style: ElevatedButton.styleFrom(                                          
                    backgroundColor: const Color(0xFF2563EB),                                          
                    foregroundColor: Colors.white,                                          
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),                                          
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),                                      
                  ),                                  
                ),                          
            ],                      
          ),                  
        ),                  
        const SizedBox(height: 16),                  
        SingleChildScrollView(                      
          scrollDirection: Axis.horizontal,                      
          child: Row(                          
            children: [                              
              _buildCategoryPill('All (${elderlyState.reminders.length})', null),                              
              const SizedBox(width: 8),                              
              _buildCategoryPill('  Pills', ReminderCategory.medication),                              
              const SizedBox(width: 8),                              
              _buildCategoryPill('  Doctors', ReminderCategory.appointment),                              
              const SizedBox(width: 8),                              
              _buildCategoryPill('  Activities', ReminderCategory.careActivity),                          
            ],                      
          ),                  
        ),                  
        const SizedBox(height: 16),                  
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
              return _buildReminderItem(rem, elderlyNotifier, !isFamily, activeElderlyId);                          
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

  Widget _buildReminderItem(Reminder rem, ElderlyNotifier notifier, bool canEdit, String activeElderlyId) {          
    final formattedDateTime = _formatReminderDateTime(rem.date, rem.time);          
    final timeDisplay = (rem.completedAt != null && rem.completedAt!.isNotEmpty) ? rem.completedAt! : "TODAY";     
    return Container(              
      padding: const EdgeInsets.all(18),              
      decoration: BoxDecoration(                  
        color: rem.isCompleted ? const Color(0xFFF8FAFC) : Colors.white,                  
        borderRadius: BorderRadius.circular(20),                  
        border: Border.all(color: rem.isCompleted ? const Color(0xFFF1F5F9) : const Color(0xFFE2E8F0)),                  
        boxShadow: rem.isCompleted ? null : [const BoxShadow(color: Color(0x08000000), blurRadius: 10, offset: Offset(0, 4))],              
      ),              
      child: Stack(                  
        children: [                      
          Column(                          
            crossAxisAlignment: CrossAxisAlignment.start,                          
            children: [                              
              Text(                                  
                rem.category.name.toLowerCase(),                                  
                style: const TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.bold),                              
              ),                              
              const SizedBox(height: 4),                              
              Text(                                  
                '  $formattedDateTime',                                  
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
              SizedBox(                                  
                width: double.infinity,                                  
                child: ElevatedButton.icon(                                      
                  onPressed: canEdit ? () => notifier.confirmMedication(rem.id, elderlyId: activeElderlyId) : null,                                      
                  icon: Icon(rem.isCompleted ? (canEdit ? Icons.refresh : Icons.check_circle) : Icons.check, size: 20),                                      
                  label: Text(                                          
                    rem.isCompleted                                               
                      ? 'DONE AT $timeDisplay ${canEdit ? "(Tap to Reset)" : ""}'                                               
                      : (canEdit ? 'MARK AS DONE' : 'PENDING'),                                          
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900),                                      
                  ),                                      
                  style: ElevatedButton.styleFrom(                                          
                    backgroundColor: rem.isCompleted ? const Color(0xFFCBD5E1) : const Color(0xFF10B981),                                          
                    foregroundColor: rem.isCompleted ? const Color(0xFF334155) : Colors.white,                                          
                    disabledBackgroundColor: rem.isCompleted ? const Color(0xFFCBD5E1) : const Color(0xFFE2E8F0),                                          
                    disabledForegroundColor: rem.isCompleted ? const Color(0xFF334155) : const Color(0xFF94A3B8),                                          
                    padding: const EdgeInsets.symmetric(vertical: 14),                                          
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),                                      
                  ),                                  
                ),                              
              ),                          
            ],                      
          ),                      
          if (canEdit)                          
            Positioned(                              
              top: -10,                              
              right: 30,                              
              child: IconButton(                                  
                icon: const Icon(Icons.edit_outlined, color: Color(0xFF2563EB)),                                  
                onPressed: () => _showAddReminderModal(activeElderlyId, existingReminder: rem),                              
              ),                          
            ),
          if (canEdit)                          
            Positioned(                              
              top: -10,                              
              right: -10,                              
              child: IconButton(                                  
                icon: const Icon(Icons.delete_outline, color: Color(0xFFEF4444)),                                  
                onPressed: () {                                      
                  notifier.deleteReminder(rem.id, elderlyId: activeElderlyId);                                  
                },                              
              ),                          
            ),                  
        ],              
      ),          
    );      
  }
}

class _AddReminderModal extends ConsumerStatefulWidget {      
  final String patientId;   
  final Reminder? existingReminder;
  const _AddReminderModal({required this.patientId, this.existingReminder});      
  @override      
  ConsumerState<_AddReminderModal> createState() => _AddReminderModalState();  
}

class _AddReminderModalState extends ConsumerState<_AddReminderModal> {      
  late TextEditingController _titleController;      
  late TextEditingController _dosageController;      
  late TextEditingController _notesController;      
  DateTime? _selectedDate;      
  String _sqlDateFormat = '';      
  TimeOfDay? _selectedTime;      
  String _sqlTimeFormat = '09:00:00';       
  late ReminderCategory _category;      
  late ReminderFrequency _frequency;      

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.existingReminder?.title ?? '');
    _dosageController = TextEditingController(text: widget.existingReminder?.dosageOrLocation ?? '');
    _notesController = TextEditingController(text: widget.existingReminder?.notes ?? '');
    _category = widget.existingReminder?.category ?? ReminderCategory.medication;
    _frequency = widget.existingReminder?.frequency ?? ReminderFrequency.daily;

    if (widget.existingReminder != null) {
      if (widget.existingReminder!.date != 'Today') {
        try {
          _selectedDate = DateFormat('yyyy-MM-dd').parse(widget.existingReminder!.date);
          _sqlDateFormat = widget.existingReminder!.date;
        } catch (_) {}
      }
      try {
        final parsedTime = DateFormat('HH:mm:ss').parse(widget.existingReminder!.time);
        _selectedTime = TimeOfDay.fromDateTime(parsedTime);
        _sqlTimeFormat = widget.existingReminder!.time;
      } catch (_) {}
    }
  }

  @override      
  void dispose() {          
    _titleController.dispose();          
    _dosageController.dispose();          
    _notesController.dispose();          
    super.dispose();      
  }

  Future<void> _pickDate() async {          
    final picked = await showDatePicker(              
      context: context,              
      initialDate: DateTime.now(),              
      firstDate: DateTime.now(),              
      lastDate: DateTime.now().add(const Duration(days: 365)),          
    );          
    if (picked != null) {              
      setState(() {                  
        _selectedDate = picked;                  
        _sqlDateFormat = DateFormat('yyyy-MM-dd').format(picked);              
      });          
    }      
  }

  Future<void> _pickTime() async {          
    final picked = await showTimePicker(              
      context: context,              
      initialTime: TimeOfDay.now(),          
    );          
    if (picked != null) {              
      setState(() {                  
        _selectedTime = picked;                  
        _sqlTimeFormat = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}:00';              
      });          
    }      
  }

  Future<void> _submit() async {          
    final title = _titleController.text.trim();          
    if (title.isEmpty || _selectedTime == null || _selectedDate == null) {              
      ScaffoldMessenger.of(context).showSnackBar(                  
        const SnackBar(content: Text('Please enter title, select a date, and a time.')),              
      );              
      return;          
    }          
    
    bool success = false;
    if (widget.existingReminder == null) {
      success = await ref.read(caregiverProvider.notifier).scheduleMedication(              
        patientId: widget.patientId,              
        medicationName: title,              
        scheduledDate: _sqlDateFormat,              
        scheduledTime: _sqlTimeFormat,              
        dosage: _dosageController.text.trim(),              
        category: _category.name,              
        frequency: _frequency.name,              
        notes: _notesController.text.trim()          
      );
    } else {
      success = await ref.read(caregiverProvider.notifier).editMedication(
        patientId: widget.patientId,
        medicationId: widget.existingReminder!.id,
        medicationName: title,
        dosage: _dosageController.text.trim(),
        scheduledDate: _sqlDateFormat,
        scheduledTime: _sqlTimeFormat,
        category: _category.name,
        frequency: _frequency.name,
        notes: _notesController.text.trim()
      );
    }
    
    if (success && mounted) {              
      Navigator.pop(context);              
      ref.read(elderlyProvider.notifier).fetchReminders(elderlyId: widget.patientId);              
      ScaffoldMessenger.of(context).showSnackBar(                  
        SnackBar(                      
          content: Text(widget.existingReminder == null ? 'New care reminder created!' : 'Care reminder updated!'),                      
          backgroundColor: const Color(0xFF10B981),                  
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
                Text(                                      
                  widget.existingReminder == null ? 'Add New Reminder' : 'Edit Reminder',                                      
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),                                  
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
                hintText: 'e.g. Morning Blood Pressure Medication',                              
              ),                          
            ),                          
            const SizedBox(height: 14),                          
            DropdownButtonFormField<ReminderCategory>(                              
              value: _category,                              
              items: ReminderCategory.values.map((cat) {                                  
                return DropdownMenuItem(value: cat, child: Text('${cat.emoji} ${cat.label}'));                              
              }).toList(),                              
              onChanged: (val) {                                  
                if (val != null) setState(() => _category = val);                              
              },                              
              decoration: const InputDecoration(labelText: 'Category'),                          
            ),                          
            const SizedBox(height: 14),                          
            Row(                              
              children: [                                  
                Expanded(                                      
                  child: OutlinedButton.icon(                                          
                    onPressed: _pickDate,                                          
                    icon: const Icon(Icons.calendar_today, size: 16),                                          
                    label: Text(_selectedDate == null ? 'Set Date' : DateFormat('MMM dd, yyyy').format(_selectedDate!)),                                          
                    style: OutlinedButton.styleFrom(                                              
                      padding: const EdgeInsets.symmetric(vertical: 20),                                          
                    ),                                      
                  ),                                  
                ),                                  
                const SizedBox(width: 12),                                  
                Expanded(                                      
                  child: OutlinedButton.icon(                                          
                    onPressed: _pickTime,                                          
                    icon: const Icon(Icons.access_time, size: 16),                                          
                    label: Text(_selectedTime == null ? 'Set Time' : _selectedTime!.format(context)),                                          
                    style: OutlinedButton.styleFrom(                                              
                      padding: const EdgeInsets.symmetric(vertical: 20),                                          
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
                labelText: 'Dosage or Location',                                  
                hintText: 'e.g. 1 Tablet (Amlodipine 5mg) with warm water',                              
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
                  foregroundColor: Colors.white,                                      
                  padding: const EdgeInsets.symmetric(vertical: 16),                                      
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),                                  
                ),                                  
                child: Text(widget.existingReminder == null ? 'CREATE REMINDER NOW' : 'SAVE CHANGES', style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.5)),                              
              ),                          
            ),                      
          ],                  
        ),              
      ),          
    );      
  }
}