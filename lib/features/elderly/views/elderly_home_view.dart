import 'package:flutter/material.dart';
import '../../../core/widgets/big_button.dart';
import '../../auth/providers/auth_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ElderlyHomeView extends ConsumerWidget {
  const ElderlyHomeView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Home Care", style: TextStyle(fontSize: 30)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, size: 35),
            onPressed: () => ref.read(authProvider.notifier).logout(),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // SOS Emergency Button - Red & Large (cite: 113, 298)
            BigButton(
              label: "🚨 SOS EMERGENCY",
              color: Colors.red,
              onPressed: () {
                // Implementation for SOS Alert (cite: 478)
              },
            ),
            const SizedBox(height: 25),
            // Medication Reminder Confirmation (cite: 105, 475)
            BigButton(
              label: "💊 I TOOK MY MEDICINE",
              color: Colors.green[700],
              onPressed: () {
                // Logic to confirm intake
              },
            ),
            const SizedBox(height: 25),
            // Daily Mood Tracking (cite: 111, 473)
            BigButton(
              label: "😊 HOW DO I FEEL?",
              color: Colors.orange[800],
              onPressed: () {
                // Open mood selector
              },
            ),
          ],
        ),
      ),
    );
  }
}