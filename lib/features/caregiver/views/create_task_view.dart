import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../services/caregiver_service.dart';

class CreateTaskView extends ConsumerStatefulWidget {
  final String patientId;
  const CreateTaskView({super.key, required this.patientId});

  @override
  ConsumerState<CreateTaskView> createState() => _CreateTaskViewState();
}

class _CreateTaskViewState extends ConsumerState<CreateTaskView> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final CaregiverService _service = CaregiverService();
  bool _isSaving = false;

  void _submitTask() async {
    final token = ref.read(authProvider).token;
    if (token == null) return;

    setState(() => _isSaving = true);
    try {
      await _service.createTask(
        token: token,
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        dueDate: DateTime.now().add(const Duration(hours: 4)).toIso8601String(),
        assignedTo: widget.patientId,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Task Assigned Successfully!")));
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Assign Care Task")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(controller: _titleController, decoration: const InputDecoration(labelText: "Task Title")),
            TextField(controller: _descController, decoration: const InputDecoration(labelText: "Task Description")),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isSaving ? null : _submitTask,
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
              child: _isSaving ? const CircularProgressIndicator() : const Text("ASSIGN TASK"),
            )
          ],
        ),
      ),
    );
  }
}