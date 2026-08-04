import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../services/elderly_service.dart';

class ElderlyMedicationView extends ConsumerStatefulWidget {
  const ElderlyMedicationView({super.key});

  @override
  ConsumerState<ElderlyMedicationView> createState() => _ElderlyMedicationViewState();
}

class _ElderlyMedicationViewState extends ConsumerState<ElderlyMedicationView> {
  final ElderlyService _service = ElderlyService();
  List<dynamic> _meds = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchMeds();
  }

  void _fetchMeds() async {
    final token = ref.read(authProvider).token;
    if (token == null) return;

    try {
      final list = await _service.getMedications(token);
      if (mounted) setState(() => _meds = list);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _confirmIntake(String medicationId) async {
    final token = ref.read(authProvider).token;
    if (token == null) return;

    try {
      await _service.confirmMedication(token: token, medicationId: medicationId, status: 'Taken');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("✅ Medicine Marked as Taken!", style: TextStyle(fontSize: 22)),
          backgroundColor: Colors.green,
        ),
      );
      _fetchMeds();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Medicine List", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
        toolbarHeight: 70,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _meds.isEmpty
              ? const Center(child: Text("No Medicine Scheduled Today", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _meds.length,
                  itemBuilder: (context, index) {
                    final item = _meds[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item['MedicationName'] ?? 'Medicine',
                                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Text("Dosage: ${item['Dosage']}",
                                style: const TextStyle(fontSize: 22, color: Colors.black87)),
                            Text("Time: ${item['ScheduledTime']}",
                                style: const TextStyle(fontSize: 22, color: Colors.teal, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              height: 60,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700),
                                icon: const Icon(Icons.check_circle, size: 32, color: Colors.white),
                                label: const Text("I TOOK THIS", style: TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold)),
                                onPressed: () => _confirmIntake(item['Id']),
                              ),
                            )
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}