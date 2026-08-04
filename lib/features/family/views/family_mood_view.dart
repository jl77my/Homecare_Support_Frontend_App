import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../services/family_service.dart';

class FamilyMoodView extends ConsumerStatefulWidget {
  final String patientId;
  const FamilyMoodView({super.key, required this.patientId});

  @override
  ConsumerState<FamilyMoodView> createState() => _FamilyMoodViewState();
}

class _FamilyMoodViewState extends ConsumerState<FamilyMoodView> {
  final FamilyService _service = FamilyService();
  List<dynamic> _moods = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchMoods();
  }

  void _fetchMoods() async {
    final token = ref.read(authProvider).token;
    if (token == null) return;

    try {
      final list = await _service.getElderlyMoods(token, widget.patientId);
      if (mounted) setState(() => _moods = list);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Elderly Daily Mood History")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _moods.isEmpty
              ? const Center(child: Text("No Mood Logs Recorded"))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _moods.length,
                  itemBuilder: (context, index) {
                    final item = _moods[index];
                    final mood = item['Mood'] ?? 'Neutral';
                    String emoji = mood == 'Happy' ? '😊' : mood == 'Sad' ? '😢' : '😐';

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: Text(emoji, style: const TextStyle(fontSize: 32)),
                        title: Text(mood, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        subtitle: Text("Logged at: ${item['DatetimeCreated']}"),
                      ),
                    );
                  },
                ),
    );
  }
}