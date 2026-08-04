import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../services/elderly_service.dart';

class ElderlyMoodView extends ConsumerStatefulWidget {
  const ElderlyMoodView({super.key});

  @override
  ConsumerState<ElderlyMoodView> createState() => _ElderlyMoodViewState();
}

class _ElderlyMoodViewState extends ConsumerState<ElderlyMoodView> {
  final ElderlyService _service = ElderlyService();
  bool _isSaving = false;

  void _selectMood(String mood) async {
    final token = ref.read(authProvider).token;
    if (token == null) return;

    setState(() => _isSaving = true);
    try {
      await _service.logMood(token: token, mood: mood);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Logged mood: $mood!", style: const TextStyle(fontSize: 22)),
          backgroundColor: Colors.indigo,
        ),
      );
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
      appBar: AppBar(
        title: const Text("How I Feel Today", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
        toolbarHeight: 70,
      ),
      body: _isSaving
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _moodButton("Happy", "😊", Colors.green),
                  const SizedBox(height: 20),
                  _moodButton("Neutral", "😐", Colors.orange),
                  const SizedBox(height: 20),
                  _moodButton("Sad", "😢", Colors.blue),
                ],
              ),
            ),
    );
  }

  Widget _moodButton(String label, String emoji, Color color) {
  return SizedBox(
    width: double.infinity,
    height: 90,
    child: ElevatedButton(
      style: ElevatedButton.styleFrom(
        // Use withValues(alpha: ...) instead of withOpacity(...)
        backgroundColor: color.withValues(alpha: 0.15),
        side: BorderSide(color: color, width: 3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      onPressed: () => _selectMood(label),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 48)),
          const SizedBox(width: 20),
          Text(
            label,
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    ),
  );
} 
}