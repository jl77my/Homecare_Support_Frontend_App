import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../services/family_service.dart';

class FamilyReportsView extends ConsumerStatefulWidget {
  final String patientId;
  const FamilyReportsView({super.key, required this.patientId});

  @override
  ConsumerState<FamilyReportsView> createState() => _FamilyReportsViewState();
}

class _FamilyReportsViewState extends ConsumerState<FamilyReportsView> {
  final FamilyService _service = FamilyService();
  List<dynamic> _reports = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchReports();
  }

  void _fetchReports() async {
    final token = ref.read(authProvider).token;
    if (token == null) return;

    try {
      final list = await _service.getCareReports(token, widget.patientId);
      if (mounted) setState(() => _reports = list);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Daily Care Reports")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _reports.isEmpty
              ? const Center(child: Text("No Care Reports Available"))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _reports.length,
                  itemBuilder: (context, index) {
                    final item = _reports[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Health Status: ${item['HealthStatusNotes'] ?? 'N/A'}", style: const TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text("Activities: ${item['DailyActivities'] ?? 'N/A'}"),
                            Text("Observations: ${item['Observations'] ?? 'N/A'}"),
                            if (item['PhotoUrl'] != null) ...[
                              const SizedBox(height: 8),
                              Image.network(item['PhotoUrl'], height: 150, errorBuilder: (_, __, ___) => const Icon(Icons.broken_image)),
                            ],
                            const SizedBox(height: 4),
                            Text("Report Date: ${item['DatetimeCreated']}", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}