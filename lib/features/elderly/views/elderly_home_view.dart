import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import 'elderly_medication_view.dart';
import 'elderly_mood_view.dart';
import '../services/elderly_service.dart';

class ElderlyHomeView extends ConsumerStatefulWidget {
  const ElderlyHomeView({super.key});

  @override
  ConsumerState<ElderlyHomeView> createState() => _ElderlyHomeViewState();
}

class _ElderlyHomeViewState extends ConsumerState<ElderlyHomeView> {
  final ElderlyService _service = ElderlyService();
  bool _isSosActive = false;

  Future<void> _triggerSos() async {
    final token = ref.read(authProvider).token;
    if (token == null) return;

    setState(() => _isSosActive = true);
    try {
      final res = await _service.triggerSos(token: token);
      if (!mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          backgroundColor: Colors.red.shade900,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text("🚨 EMERGENCY ALERT",
              style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
          content: Text(res['message'] ?? 'Alert Sent!',
              style: const TextStyle(color: Colors.white, fontSize: 22)),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.red.shade900,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text("DISMISS", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            )
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _isSosActive = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.amber.shade50, // High Contrast Background
      appBar: AppBar(
        backgroundColor: Colors.teal.shade800,
        toolbarHeight: 70,
        title: const Text("My Care Home",
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, size: 32, color: Colors.white),
            onPressed: () => ref.read(authProvider.notifier).logout(),
          )
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. OVERSIZED SOS EMERGENCY BUTTON
              Expanded(
                flex: 3,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade700,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    elevation: 10,
                  ),
                  onPressed: _isSosActive ? null : _triggerSos,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.warning_amber_rounded, size: 90),
                      const SizedBox(height: 10),
                      Text(
                        _isSosActive ? "SENDING..." : "PRESS FOR HELP\n(SOS)",
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, height: 1.2),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // 2. MY MEDICINE SHORTCUT
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal.shade700,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  icon: const Icon(Icons.medication, size: 48),
                  label: const Text("My Medicine", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ElderlyMedicationView()),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // 3. DAILY MOOD SHORTCUT
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo.shade700,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  icon: const Icon(Icons.sentiment_satisfied_alt, size: 48),
                  label: const Text("How I Feel Today", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ElderlyMoodView()),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}