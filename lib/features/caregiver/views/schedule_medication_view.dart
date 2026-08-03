import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../services/caregiver_service.dart';

class ScheduleMedicationView extends ConsumerStatefulWidget {
  final String patientId;
  const ScheduleMedicationView({super.key, required this.patientId});

  @override
  ConsumerState<ScheduleMedicationView> createState() => _ScheduleMedicationViewState();
}

class _ScheduleMedicationViewState extends ConsumerState<ScheduleMedicationView> {
  final _nameController = TextEditingController();
  final _dosageController = TextEditingController();
  final _timeController = TextEditingController(text: "08:00:00");
  final CaregiverService _service = CaregiverService();
  bool _isSaving = false;

  void _submitMedication() async {
    final token = ref.read(authProvider).token;
    if (token == null) return;

    setState(() => _isSaving = true);
    try {
      await _service.scheduleMedication(
        token: token,
        patientId: widget.patientId,
        medicationName: _nameController.text.trim(),
        dosage: _dosageController.text.trim(),
        scheduledTime: _timeController.text.trim(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Medication Scheduled!")));
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
      appBar: AppBar(title: const Text("Schedule Medication")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(controller: _nameController, decoration: const InputDecoration(labelText: "Medication Name")),
            TextField(controller: _dosageController, decoration: const InputDecoration(labelText: "Dosage (e.g. 500mg)")),
            TextField(controller: _timeController, decoration: const InputDecoration(labelText: "Scheduled Time (HH:MM:SS)")),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isSaving ? null : _submitMedication,
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
              child: _isSaving ? const CircularProgressIndicator() : const Text("SAVE SCHEDULE"),
            )
          ],
        ),
      ),
    );
  }
}