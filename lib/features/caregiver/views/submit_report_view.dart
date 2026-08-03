import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../services/caregiver_service.dart';

class SubmitReportView extends ConsumerStatefulWidget {
  final String patientId;
  const SubmitReportView({super.key, required this.patientId});

  @override
  ConsumerState<SubmitReportView> createState() => _SubmitReportViewState();
}

class _SubmitReportViewState extends ConsumerState<SubmitReportView> {
  final _notesController = TextEditingController();
  final _activitiesController = TextEditingController();
  final _obsController = TextEditingController();
  final _photoController = TextEditingController();
  final CaregiverService _service = CaregiverService();
  bool _isSaving = false;

  void _submitReport() async {
    final token = ref.read(authProvider).token;
    if (token == null) return;

    setState(() => _isSaving = true);
    try {
      await _service.submitCareReport(
        token: token,
        patientId: widget.patientId,
        healthStatusNotes: _notesController.text.trim(),
        dailyActivities: _activitiesController.text.trim(),
        observations: _obsController.text.trim(),
        photoUrl: _photoController.text.trim().isEmpty ? null : _photoController.text.trim(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Care Report Submitted!")));
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
      appBar: AppBar(title: const Text("Submit Care Report")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(controller: _notesController, decoration: const InputDecoration(labelText: "Health Status Notes")),
            TextField(controller: _activitiesController, decoration: const InputDecoration(labelText: "Daily Activities")),
            TextField(controller: _obsController, decoration: const InputDecoration(labelText: "Observations")),
            TextField(controller: _photoController, decoration: const InputDecoration(labelText: "Photo URL (Optional)")),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isSaving ? null : _submitReport,
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
              child: _isSaving ? const CircularProgressIndicator() : const Text("SUBMIT REPORT"),
            )
          ],
        ),
      ),
    );
  }
}