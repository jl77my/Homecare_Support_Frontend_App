import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';

class CaregiverHomeView extends ConsumerWidget {
  const CaregiverHomeView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Caregiver Dashboard"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authProvider.notifier).logout(),
          )
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildTaskSummaryCard(context),
          const SizedBox(height: 20),
          _buildActionTile(context, Icons.favorite, "Record Health Data", () {
             // Navigate to Health Form (cite: 106, 466)
          }),
          _buildActionTile(context, Icons.assignment, "Daily Care Report", () {
             // Navigate to Report Form (cite: 109, 470)
          }),
          _buildActionTile(context, Icons.chat, "Chat with Family", () {
             // Navigate to In-app Chat (cite: 112, 465)
          }),
        ],
      ),
    );
  }

  Widget _buildTaskSummaryCard(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Today's Tasks", style: Theme.of(context).textTheme.headlineSmall),
            const Divider(),
            const Text("• Morning Medication (Pending)"),
            const Text("• Physical Therapy (Pending)"),
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile(BuildContext context, IconData icon, String title, VoidCallback onTap) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).primaryColor),
        title: Text(title),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}