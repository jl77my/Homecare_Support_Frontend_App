// lib/features/caregiver/views/tasks_view.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/models/enums.dart';
import '../../../core/models/models.dart';
import '../../auth/providers/auth_provider.dart';
import '../../caregiver/providers/caregiver_provider.dart';
import '../../family/providers/family_provider.dart';
import '../../family/views/family_pairing_view.dart';
import '../widgets/patient_selector_bar.dart';
import 'pairing_view.dart';

class TasksView extends ConsumerStatefulWidget {
    const TasksView({super.key});
    @override
    ConsumerState<TasksView> createState() => _TasksViewState();
}

class _TasksViewState extends ConsumerState<TasksView> {
    bool _showActiveTasks = true;

    @override
    void initState() {
        super.initState();
        Future.microtask(() {
            final authUser = ref.read(authProvider).user;
            final isFamily = authUser?.role.toLowerCase() == 'family';
            if (isFamily) {
                final activeId = ref.read(familyDashboardProvider).selectedElderlyId;
                if (activeId.isNotEmpty) ref.read(familyDashboardProvider.notifier).fetchCareTasks(activeId);
            } else {
                final activeId = ref.read(caregiverProvider).activeElderlyId;
                if (activeId.isNotEmpty) ref.read(caregiverProvider.notifier).fetchCareTasks(activeId);
            }
        });
    }

    Future<void> _handleRefresh(bool isFamily, String activeElderlyId) async {
        if (activeElderlyId.isEmpty) return;
        if (isFamily) {
            await ref.read(familyDashboardProvider.notifier).fetchCareTasks(activeElderlyId);
        } else {
            await ref.read(caregiverProvider.notifier).fetchCareTasks(activeElderlyId);
        }
    }

    void _showAddTaskModal(String userRole, String activeElderlyId, bool isFamily, {CareTask? existingTask}) {
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
            builder: (context) => _AddTaskModal(
                patientId: activeElderlyId,
                userRole: userRole,
                isFamily: isFamily,
       existingTask: existingTask,
     ),
        );
    }

    @override
    Widget build(BuildContext context) {
        final authUser = ref.watch(authProvider).user;
        final isFamily = authUser?.role.toLowerCase() == 'family';

        final caregiverState = ref.watch(caregiverProvider);
        final familyState = ref.watch(familyDashboardProvider);
        
        final allTasks = isFamily ? familyState.tasks : caregiverState.tasks;
        final assignedSeniors = isFamily ? familyState.linkedSeniors : caregiverState.assignedSeniors;
        final activeElderlyId = isFamily ? familyState.selectedElderlyId : caregiverState.activeElderlyId;
        final isLoading = isFamily ? familyState.isLoading : caregiverState.isLoading;
        
        final displayedTasks = allTasks.where((t) {
            if (_showActiveTasks) return t.status == TaskStatus.pending;
            return t.status == TaskStatus.done;
        }).toList();
        
        final doneCount = allTasks.where((t) => t.status == TaskStatus.done).length;
        final roleLabel = isFamily ? 'Family Member' : 'Caregiver';
        
        return RefreshIndicator(
            onRefresh: () => _handleRefresh(isFamily, activeElderlyId),
            color: const Color(0xFF075DBB),
            child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 32),
                children: [
                    PatientSelectorBar(
                        assignedSeniors: assignedSeniors,
                        selectedElderlyId: activeElderlyId,
                        onElderlySelected: (newElderlyId) {
                            if (isFamily) {
                                ref.read(familyDashboardProvider.notifier).switchElderlyContext(newElderlyId);
                            } else {
                                ref.read(caregiverProvider.notifier).switchElderlyContext(newElderlyId);
                            }
                        },
                        onPairNewElderly: () {
                            Navigator.of(context).push(
                                MaterialPageRoute(builder: (context) => isFamily ? const FamilyPairingView() : const PairingView()),
                            );
                        },
                    ),

                    Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                                Expanded(
                                    child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                            const Text(
                                                'Daily Care Tasks',
                                                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                                            ),
                                            const SizedBox(height: 2),
                                             ],
                                    ),
                                ),
                                ElevatedButton.icon(
                                    onPressed: () => _showAddTaskModal(roleLabel, activeElderlyId, isFamily),
                                    icon: const Icon(Icons.add, size: 18),
                                    label: const Text('ADD TASK', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900)),
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF075DBB),
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    ),
                                ),
                            ],
                        ),
                    ),
                    const SizedBox(height: 16),

                    Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                            children: [
                                Expanded(
                                    child: ChoiceChip(
                                        label: const Center(child: Text('Active Tasks', style: TextStyle(fontWeight: FontWeight.bold))),
                                        selected: _showActiveTasks,
                                        onSelected: (val) => setState(() => _showActiveTasks = true),
                                        selectedColor: const Color(0xFF075DBB),
                                        labelStyle: TextStyle(color: _showActiveTasks ? Colors.white : const Color(0xFF64748B)),
                                    ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                    child: ChoiceChip(
                                        label: const Center(child: Text('Task History', style: TextStyle(fontWeight: FontWeight.bold))),
                                        selected: !_showActiveTasks,
                                        onSelected: (val) => setState(() => _showActiveTasks = false),
                                        selectedColor: const Color(0xFF075DBB),
                                        labelStyle: TextStyle(color: !_showActiveTasks ? Colors.white : const Color(0xFF64748B)),
                                    ),
                                ),
                            ],
                        ),
                    ),
                    const SizedBox(height: 16),

                    if (isLoading)
                        const Padding(
                            padding: EdgeInsets.symmetric(vertical: 40),
                            child: Center(child: CircularProgressIndicator()),
                        )
                    else if (displayedTasks.isEmpty)
                        Padding(
                            padding: const EdgeInsets.symmetric(vertical: 40),
                            child: Center(
                                child: Column(
                                    children: [
                                        Icon(
                                            _showActiveTasks ? Icons.check_box_outlined : Icons.history,
                                            size: 54,
                                            color: const Color(0xFFCBD5E1),
                                        ),
                                        const SizedBox(height: 10),
                                        Text(
                                            _showActiveTasks ? 'No active tasks pending' : 'No completed tasks yet',
                                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                                        ),
                                    ],
                                ),
                            ),
                        )
                    else
                        ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: displayedTasks.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                                final task = displayedTasks[index];
                                final isDone = task.status == TaskStatus.done;
                                               
                                final formattedDate = DateFormat('MMM dd, yyyy - hh:mm a').format(task.scheduledTime.toLocal());

                                return Container(
                                    margin: const EdgeInsets.symmetric(horizontal: 16),
                                    padding: const EdgeInsets.all(18),
                                    decoration: BoxDecoration(
                                        color: isDone ? const Color(0xFFF8FAFC) : Colors.white,
                                        borderRadius: BorderRadius.circular(24),
                                        border: Border.all(color: isDone ? const Color(0xFFF1F5F9) : const Color(0xFFE2E8F0)),
                                    ),
                                    child: Row(
                                        children: [
                                            Checkbox(
                                                value: isDone,
                                                onChanged: (bool? value) async {
                                                    final newStatus = value == true ? 'Completed' : 'Pending';
                                                    final success = isFamily
                                                            ? await ref.read(familyDashboardProvider.notifier).updateTaskStatus(task.id, newStatus)
                                                            : await ref.read(caregiverProvider.notifier).updateTaskStatus(task.id, newStatus);

                                                    if (success && context.mounted) {
                                                        ScaffoldMessenger.of(context).showSnackBar(
                                                            SnackBar(
                                                                content: Text('Task marked as ${value == true ? "completed" : "pending"}!'),
                                                                backgroundColor: const Color(0xFF10B981),
                                                            ),
                                                        );
                                                    }
                                                },
                                                activeColor: const Color(0xFF10B981),
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                                child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                        Text(
                                                            task.title,
                                                            style: TextStyle(
                                                                fontSize: 16,
                                                                fontWeight: FontWeight.w800,
                                                                color: isDone ? const Color(0xFF94A3B8) : const Color(0xFF0F172A),
                                                                decoration: isDone ? TextDecoration.lineThrough : null,
                                                            ),
                                                        ),
                                                        const SizedBox(height: 4),
                                                        Text(
                                                            '📅 $formattedDate',
                                                             style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF075DBB)),
                                                        ),
                                                        if (task.description.isNotEmpty) ...[
                                                            const SizedBox(height: 2),
                                                            Text(task.description, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                                                        ],
                                                    ],
                                                ),
                                            ),
                       if (isFamily || roleLabel == 'Caregiver')
                          IconButton(
                           icon: const Icon(Icons.edit_outlined, size: 20, color: Color(0xFF94A3B8)),
                           onPressed: () => _showAddTaskModal(roleLabel, activeElderlyId, isFamily, existingTask: task),
                         ),
                       Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                decoration: BoxDecoration(
                                                    color: isDone ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
                                                    borderRadius: BorderRadius.circular(12),
                                                ),
                                                child: Text(
                                                    task.status.label,
                                                    style: TextStyle(
                                                        fontSize: 10,
                                                        fontWeight: FontWeight.w900,
                                                        color: isDone ? const Color(0xFF15803D) : const Color(0xFFB45309),
                                                    ),
                                                ),
                                            ),
                                        ],
                                    ),
                                );
                            },
                        ),
                ],
            ),
        );
    }
}

// _AddTaskModal and state logic remains unchanged
class _AddTaskModal extends ConsumerStatefulWidget {
    final String patientId;
    final String userRole;
    final bool isFamily;
    final CareTask? existingTask;

  const _AddTaskModal({required this.patientId, required this.userRole, required this.isFamily, this.existingTask});

    @override
    ConsumerState<_AddTaskModal> createState() => _AddTaskModalState();
}

class _AddTaskModalState extends ConsumerState<_AddTaskModal> {
    late TextEditingController _titleController;
    late TextEditingController _descController;
    DateTime? _selectedDate;
    TimeOfDay? _selectedTime;

    @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.existingTask?.title ?? '');
    _descController = TextEditingController(text: widget.existingTask?.description ?? '');
    if (widget.existingTask != null) {
      _selectedDate = widget.existingTask!.scheduledTime;
      _selectedTime = TimeOfDay.fromDateTime(widget.existingTask!.scheduledTime.toLocal());
    }
  }

    @override
    void dispose() {
        _titleController.dispose();
        _descController.dispose();
        super.dispose();
    }

    Future<void> _pickDate() async {
        final picked = await showDatePicker(
            context: context,
            initialDate: _selectedDate ?? DateTime.now(),
            firstDate: DateTime.now(),
            lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (picked != null) setState(() => _selectedDate = picked);
    }

    Future<void> _pickTime() async {
        final picked = await showTimePicker(
            context: context,
            initialTime: _selectedTime ?? TimeOfDay.now(),
        );
        if (picked != null) setState(() => _selectedTime = picked);
    }

    Future<void> _submitTask() async {
        final title = _titleController.text.trim();
        if (title.isEmpty || _selectedDate == null || _selectedTime == null) {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please enter title, date, and time.')),
            );
            return;
        }

        final combinedDateTime = DateTime(
            _selectedDate!.year,
            _selectedDate!.month,
            _selectedDate!.day,
            _selectedTime!.hour,
            _selectedTime!.minute,
        );
        
        bool success = false;
    if (widget.existingTask == null) {
      success = widget.isFamily
                 ? await ref.read(familyDashboardProvider.notifier).createTask(
                         elderlyId: widget.patientId,
                         title: title,
                         description: _descController.text.trim(),
                         dueDate: combinedDateTime.toIso8601String(),
                     )
                 : await ref.read(caregiverProvider.notifier).createTask(
                         title: title,
                         description: _descController.text.trim(),
                         dueDate: combinedDateTime.toIso8601String(),
                         assignedTo: widget.patientId,
                     );
    } else {
      success = widget.isFamily
                 ? await ref.read(familyDashboardProvider.notifier).editTask(
                         taskId: widget.existingTask!.id,
             elderlyId: widget.patientId,
                        title: title,
                         description: _descController.text.trim(),
                         dueDate: combinedDateTime.toIso8601String(),
                     )
                 : await ref.read(caregiverProvider.notifier).editTask(
                         taskId: widget.existingTask!.id,
            title: title,
                         description: _descController.text.trim(),
                         dueDate: combinedDateTime.toIso8601String(),
                         assignedTo: widget.patientId,
                     );
    }

    if (success && mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text(widget.existingTask == null ? 'Care task created!' : 'Care task updated!'),
                    backgroundColor: const Color(0xFF10B981),
                ),
            );
        }
    }

    @override
    Widget build(BuildContext context) {
        final isLoading = widget.isFamily
               ? ref.watch(familyDashboardProvider).isLoading
               : ref.watch(caregiverProvider).isLoading;

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
            child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                    Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                            Text(widget.existingTask == null ? 'Add Task' : 'Edit Task', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                            IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                        ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                        controller: _titleController,
                        decoration: const InputDecoration(labelText: 'Task Title', hintText: 'e.g., Patio Walking Assistance'),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                        controller: _descController,
                        decoration: const InputDecoration(labelText: 'Description', hintText: 'e.g., 20 mins light walk with walker'),
                    ),
                    const SizedBox(height: 16),
                    Row(
                        children: [
                            Expanded(
                                child: OutlinedButton.icon(
                                    onPressed: _pickDate,
                                    icon: const Icon(Icons.calendar_today, size: 16),
                                    label: Text(_selectedDate == null ? 'Set Date' : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'),
                                ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                                child: OutlinedButton.icon(
                                    onPressed: _pickTime,
                                    icon: const Icon(Icons.access_time, size: 16),
                                    label: Text(_selectedTime == null ? 'Set Time' : _selectedTime!.format(context)),
                                ),
                            ),
                        ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                            onPressed: isLoading ? null : _submitTask,
                            style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF075DBB),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            ),
                            child: isLoading
                                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                  : Text(widget.existingTask == null ? 'ADD TASK' : 'SAVE CHANGES', style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white)),
                        ),
                    ),
                ],
            ),
        );
    }
}
