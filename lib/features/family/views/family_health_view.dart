import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../services/family_service.dart';

class FamilyHealthView extends ConsumerStatefulWidget {
  final String patientId;
  const FamilyHealthView({super.key, required this.patientId});

  @override
  ConsumerState<FamilyHealthView> createState() => _FamilyHealthViewState();
}

class _FamilyHealthViewState extends ConsumerState<FamilyHealthView> {
  final FamilyService _service = FamilyService();
  List<dynamic> _records = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchHealth();
  }

  void _fetchHealth() async {
    final token = ref.read(authProvider).token;
    if (token == null) return;

    try {
      final list = await _service.getHealthRecords(token, widget.patientId);
      if (mounted) setState(() => _records = list);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Health Vitals & Alerts")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _records.isEmpty
              ? const Center(child: Text("No Health Vitals Recorded"))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _records.length,
                  itemBuilder: (context, index) {
                    final item = _records[index];
                    List alerts = item['alerts'] ?? [];

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        side: alerts.isNotEmpty ? const BorderSide(color: Colors.red, width: 2) : BorderSide.none,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (alerts.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.all(8),
                                margin: const EdgeInsets.only(bottom: 8),
                                color: Colors.red.shade100,
                                child: Text(alerts.join('\n'), style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                              ),
                            Text("Heart Rate: ${item['HeartRate'] ?? 'N/A'} BPM"),
                            Text("Blood Pressure: ${item['BloodPressure'] ?? 'N/A'}"),
                            Text("Blood Sugar: ${item['BloodSugar'] ?? 'N/A'} mmol/L"),
                            if (item['Notes'] != null) Text("Notes: ${item['Notes']}"),
                            Text("Logged: ${item['DatetimeCreated']}", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}