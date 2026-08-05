import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/enums.dart';
import '../../auth/providers/auth_provider.dart';
import '../../caregiver/providers/caregiver_provider.dart';

class TasksView extends ConsumerStatefulWidget {
  final String patientId;

  const TasksView({
    super.key,
    this.patientId = "00000000-0000-0000-0000-000000000000",
  });

  @override
  ConsumerState<TasksView> createState() => _TasksViewState();
}

class _TasksViewState extends ConsumerState<TasksView> {
  void _showAddTaskModal(String userRole) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddTaskModal(
        patientId: widget.patientId,
        userRole: userRole,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authUser = ref.watch(authProvider).user;
    final caregiverState = ref.watch(caregiverProvider);
    final tasks = caregiverState.tasks;
    final doneCount = tasks.where((t) => t.status == TaskStatus.done).length;

    final roleLabel = (authUser?.role == 'family' || authUser?.role == 'Family')
        ? 'Family Member'
        : 'Caregiver';

    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        // Header Card
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
                    'Daily Care Checklist',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$doneCount of ${tasks.length} tasks completed today',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () => _showAddTaskModal(roleLabel),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('ADD TASK', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F172A),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Tasks List
        if (caregiverState.isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (tasks.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.check_box_outlined, size: 54, color: Color(0xFFCBD5E1)),
                  SizedBox(height: 10),
                  Text(
                    'No care tasks assigned for today',
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
            itemCount: tasks.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final task = tasks[index];
              final isDone = task.status == TaskStatus.done;
              return Container(
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
                      onChanged: (_) {},
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
                          if (task.description.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(task.description, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                          ],
                        ],
                      ),
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
    );
  }
}

class _AddTaskModal extends ConsumerStatefulWidget {
  final String patientId;
  final String userRole;

  const _AddTaskModal({required this.patientId, required this.userRole});

  @override
  ConsumerState<_AddTaskModal> createState() => _AddTaskModalState();
}

class _AddTaskModalState extends ConsumerState<_AddTaskModal> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _submitTask() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a task title.')),
      );
      return;
    }

    final success = await ref.read(caregiverProvider.notifier).createTask(
          title: title,
          description: _descController.text.trim(),
          dueDate: DateTime.now().add(const Duration(hours: 4)).toIso8601String(),
          assignedTo: widget.patientId,
        );

    if (success && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Care task created by ${widget.userRole} & synchronized!'),
          backgroundColor: const Color(0xFF10B981),
        ),
      );
    } else if (mounted) {
      final error = ref.read(caregiverProvider).errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error ?? 'Failed to assign care task.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(caregiverProvider).isLoading;

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
              Text('Add Task (${widget.userRole})', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Task Title',
              hintText: 'e.g., Patio Walking Assistance',
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _descController,
            decoration: const InputDecoration(
              labelText: 'Description',
              hintText: 'e.g., 20 mins light walk with walker',
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isLoading ? null : _submitTask,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: isLoading
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('ADD TASK', style: TextStyle(fontWeight: FontWeight.w900)),
            ),
          ),
        ],
      ),
    );
  }
}