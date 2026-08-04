import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import 'family_tasks_view.dart';
import 'family_health_view.dart';
import 'family_reports_view.dart';
import 'family_mood_view.dart';
import 'family_chat_view.dart';

class FamilyHomeView extends ConsumerWidget {
  const FamilyHomeView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Replace with target elderly patient GUID in production
    const samplePatientId = "00000000-0000-0000-0000-000000000000";
    const sampleCaregiverId = "00000000-0000-0000-0000-000000000000";

    return Scaffold(
      appBar: AppBar(
        title: const Text("Family Remote Dashboard"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authProvider.notifier).logout(),
          )
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          ListTile(
            leading: const Icon(Icons.task, color: Colors.blue),
            title: const Text("1. Care Tasks Progress"),
            subtitle: const Text("Monitor real-time task status"),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FamilyTasksView(patientId: samplePatientId))),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.favorite, color: Colors.red),
            title: const Text("2. Health Vitals & Alerts"),
            subtitle: const Text("View HR, BP, Glucose and health warnings"),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FamilyHealthView(patientId: samplePatientId))),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.article, color: Colors.orange),
            title: const Text("3. Daily Care Reports"),
            subtitle: const Text("Read caregiver observations & photo proof"),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FamilyReportsView(patientId: samplePatientId))),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.emoji_emotions, color: Colors.purple),
            title: const Text("4. Elderly Daily Mood"),
            subtitle: const Text("Check overall emotional well-being"),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FamilyMoodView(patientId: samplePatientId))),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.chat, color: Colors.green),
            title: const Text("5. In-App Chat with Caregiver"),
            subtitle: const Text("Direct messaging for care coordination"),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FamilyChatView(caregiverId: sampleCaregiverId))),
          ),
        ],
      ),
    );
  }
}