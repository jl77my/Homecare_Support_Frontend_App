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
    try {
      final result = await _service.recordHealth(
        token: token,
        patientId: widget.patientId,
        heartRate: _hrController.text.trim(),
        bloodPressure: _bpController.text.trim(),
        bloodSugar: _sugarController.text.trim(),
        notes: _notesController.text.trim(),
      );

      if (!mounted) return;
      List alerts = result['alerts'] ?? [];
      String message = alerts.isNotEmpty ? "⚠️ ALERTS:\n${alerts.join('\n')}" : "Health record saved!";

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text(alerts.isNotEmpty ? "Health Warning" : "Success"),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text("OK"),
            )
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _isSaving = false);
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
            TextField(controller: _bpController, decoration: const InputDecoration(labelText: "Blood Pressure (e.g. 145/95)")),
            TextField(controller: _sugarController, decoration: const InputDecoration(labelText: "Blood Sugar (mmol/L)")),
            TextField(controller: _notesController, decoration: const InputDecoration(labelText: "Notes")),
            const SizedBox(height: 20),
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