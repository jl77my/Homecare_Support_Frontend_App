import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../services/family_service.dart';

class FamilyTasksView extends ConsumerStatefulWidget {
  final String patientId;
  const FamilyTasksView({super.key, required this.patientId});

  @override
  ConsumerState<FamilyTasksView> createState() => _FamilyTasksViewState();
}

class _FamilyTasksViewState extends ConsumerState<FamilyTasksView> {
  final FamilyService _service = FamilyService();
  List<dynamic> _tasks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchTasks();
  }

  void _fetchTasks() async {
    final token = ref.read(authProvider).token;
    if (token == null) return;

    try {
      final list = await _service.getCareTasks(token, widget.patientId);
      if (mounted) setState(() => _tasks = list);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Care Tasks Progress")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _tasks.isEmpty
              ? const Center(child: Text("No Care Tasks Logged"))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _tasks.length,
                  itemBuilder: (context, index) {
                    final item = _tasks[index];
                    final isCompleted = item['Status'] == 'Completed';
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: Icon(
                          isCompleted ? Icons.check_circle : Icons.pending,
                          color: isCompleted ? Colors.green : Colors.orange,
                        ),
                        title: Text(item['Title'] ?? 'Task', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text("${item['Description'] ?? ''}\nDue: ${item['DueDate'] ?? 'N/A'}"),
                        trailing: Chip(
                          label: Text(item['Status'] ?? 'Pending'),
                          backgroundColor: isCompleted ? Colors.green.shade100 : Colors.orange.shade100,
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}