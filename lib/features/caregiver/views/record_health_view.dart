import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../services/caregiver_service.dart';

class RecordHealthView extends ConsumerStatefulWidget {
  final String patientId;
  const RecordHealthView({super.key, required this.patientId});

  @override
  ConsumerState<RecordHealthView> createState() => _RecordHealthViewState();
}

class _RecordHealthViewState extends ConsumerState<RecordHealthView> {
  final _hrController = TextEditingController();
  final _bpController = TextEditingController();
  final _sugarController = TextEditingController();
  final _notesController = TextEditingController();
  final CaregiverService _service = CaregiverService();
  bool _isSaving = false;

  void _submitVitals() async {
    final token = ref.read(authProvider).token;
    if (token == null) return;

    setState(() => _isSaving = true);
    final result = await _service.recordHealth(
      token,
      widget.patientId,
      _hrController.text.trim(),
      _bpController.text.trim(),
      _sugarController.text.trim(),
      _notesController.text.trim(),
    );
    setState(() => _isSaving = false);

    if (!mounted) return;

    if (result.containsKey('recordId')) {
      List alerts = result['alerts'] ?? [];
      String message = alerts.isNotEmpty 
          ? "⚠️ ALERTS TRIGGERED:\n${alerts.join('\n')}" 
          : "Health record saved successfully!";

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text(alerts.isNotEmpty ? "Health Warning" : "Success"),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop(); // Navigate back to dashboard
              },
              child: const Text("OK"),
            )
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Record Vitals")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(controller: _hrController, decoration: const InputDecoration(labelText: "Heart Rate (BPM)")),
            const SizedBox(height: 12),
            TextField(controller: _bpController, decoration: const InputDecoration(labelText: "Blood Pressure (e.g. 145/95)")),
            const SizedBox(height: 12),
            TextField(controller: _sugarController, decoration: const InputDecoration(labelText: "Blood Glucose (mmol/L)")),
            const SizedBox(height: 12),
            TextField(controller: _notesController, decoration: const InputDecoration(labelText: "Observations / Notes")),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isSaving ? null : _submitVitals,
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
              child: _isSaving ? const CircularProgressIndicator() : const Text("SUBMIT HEALTH RECORD"),
            )
          ],
        ),
      ),
    );
  }
}