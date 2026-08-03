import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import 'record_health_view.dart';
import 'schedule_medication_view.dart';
import 'create_task_view.dart';
import 'submit_report_view.dart';
import 'caregiver_chat_view.dart';

class CaregiverHomeView extends ConsumerWidget {
  const CaregiverHomeView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const samplePatientId = "00000000-0000-0000-0000-000000000000";

    return Scaffold(
      appBar: AppBar(
        title: const Text("Caregiver Workspace"),
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
            leading: const Icon(Icons.assignment, color: Colors.blue),
            title: const Text("1. Assign Care Task"),
            subtitle: const Text("Create daily tasks for elderly or family"),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateTaskView(patientId: samplePatientId))),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.medication, color: Colors.purple),
            title: const Text("2. Schedule Medication"),
            subtitle: const Text("Set medication dosage and daily time"),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ScheduleMedicationView(patientId: samplePatientId))),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.favorite, color: Colors.red),
            title: const Text("3. Record Health Vitals"),
            subtitle: const Text("Input HR, BP, Glucose and receive rule alerts"),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RecordHealthView(patientId: samplePatientId))),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.note_add, color: Colors.orange),
            title: const Text("4. Submit Care Report"),
            subtitle: const Text("Log observations and upload photo evidence"),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SubmitReportView(patientId: samplePatientId))),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.chat, color: Colors.green),
            title: const Text("5. In-App Chat"),
            subtitle: const Text("Message family members directly"),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CaregiverChatView(receiverId: samplePatientId))),
          ),
        ],
      ),
    );
  }
}