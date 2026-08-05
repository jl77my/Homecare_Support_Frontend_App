import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';

class CareConnectionsView extends ConsumerWidget {
  const CareConnectionsView({super.key});

  void _confirmDelete(BuildContext context, String connectionId, String name, String role) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Remove $name?'),
        content: Text('Are you sure you want to remove $name ($role) from this care team?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$name removed from care connections.')));
            },
            child: const Text('REMOVE', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final role = user?.role.toLowerCase() ?? 'elderly';
    final isElderly = role == 'elderly';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(isElderly ? 'My Care Connections' : 'Care Connections', style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w900)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // 1. Caregivers Section
          const Text('CAREGIVERS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF64748B), letterSpacing: 1.0)),
          const SizedBox(height: 10),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: ListTile(
              leading: const CircleAvatar(backgroundColor: Color(0xFFEFF6FF), child: Icon(Icons.medical_services, color: Color(0xFF2563EB))),
              title: const Text('John Lim', style: TextStyle(fontWeight: FontWeight.w900)),
              subtitle: const Text('Status: Active', style: TextStyle(color: Color(0xFF22C55E), fontWeight: FontWeight.bold, fontSize: 12)),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline, color: Color(0xFFEF4444)),
                onPressed: () => _confirmDelete(context, 'conn-1', 'John Lim', 'Caregiver'),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // 2. Family Members Section
          const Text('FAMILY MEMBERS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF64748B), letterSpacing: 1.0)),
          const SizedBox(height: 10),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Column(
              children: [
                ListTile(
                  leading: const CircleAvatar(backgroundColor: Color(0xFFFEF2F2), child: Icon(Icons.family_restroom, color: Color(0xFFEF4444))),
                  title: const Text('Mary Tan', style: TextStyle(fontWeight: FontWeight.w900)),
                  trailing: isElderly
                      ? IconButton(
                          icon: const Icon(Icons.delete_outline, color: Color(0xFFEF4444)),
                          onPressed: () => _confirmDelete(context, 'conn-2', 'Mary Tan', 'Family'),
                        )
                      : null, // Family cannot delete other family members
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const CircleAvatar(backgroundColor: Color(0xFFFEF2F2), child: Icon(Icons.family_restroom, color: Color(0xFFEF4444))),
                  title: const Text('David Tan', style: TextStyle(fontWeight: FontWeight.w900)),
                  trailing: isElderly
                      ? IconButton(
                          icon: const Icon(Icons.delete_outline, color: Color(0xFFEF4444)),
                          onPressed: () => _confirmDelete(context, 'conn-3', 'David Tan', 'Family'),
                        )
                      : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}