// lib/features/caregiver/views/care_connections_view.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../../family/providers/family_provider.dart';
import '../../caregiver/providers/caregiver_provider.dart';
import '../../elderly/providers/elderly_provider.dart';

class CareConnectionsView extends ConsumerWidget {
  final VoidCallback onBack;

  const CareConnectionsView({super.key, required this.onBack});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    if (user == null) return const SizedBox.shrink();

    final role = user.role.toLowerCase();
    final isElderly = role == 'elderly';

    // 1. DYNAMIC DATA FETCHING BASED ON ROLE
    List<dynamic> caregivers = [];
    List<dynamic> familyMembers = [];

    if (isElderly) {
      caregivers = ref.watch(elderlyProvider).activeCaregivers;
      familyMembers = ref.watch(elderlyProvider).activeFamilyMembers;
    } else if (role == 'family') {
      caregivers = ref.watch(familyDashboardProvider).activeCaregivers;
      familyMembers = ref.watch(familyDashboardProvider).activeFamilyMembers;
    } else if (role == 'caregiver') {
      caregivers = ref.watch(caregiverProvider).activeCaregivers;
      familyMembers = ref.watch(caregiverProvider).activeFamilyMembers;
    }

    // 2. PRIVILEGE EVALUATION FOR UI RENDERING
    bool _canRemove(String targetRole, String targetUserId) {
      if (isElderly) return true; // Elderly can remove anyone
      if (role == 'family') return targetRole == 'caregiver' || targetUserId == user.id; // Family can remove caregivers or self
      if (role == 'caregiver') return targetUserId == user.id; // Caregiver can only remove self
      return false;
    }

    void _executeDelete(String connectionId) {
      if (isElderly) {
        ref.read(elderlyProvider.notifier).deleteCareConnection(connectionId);
      } else if (role == 'family') {
        ref.read(familyDashboardProvider.notifier).deleteCareConnection(connectionId);
      } else if (role == 'caregiver') {
        ref.read(caregiverProvider.notifier).deleteCareConnection(connectionId);
      }
    }

    void _confirmDelete(BuildContext context, String connectionId, String name, String targetRole) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Remove $name?'),
          content: Text('Are you sure you want to remove $name ($targetRole) from this care team?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
              onPressed: () {
                Navigator.pop(context);
                _executeDelete(connectionId);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$name removed from care connections.')));
              },
              child: const Text('REMOVE', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }

    // 3. DYNAMIC CARD BUILDER
    Widget _buildConnectionCard(dynamic conn, String targetRole) {
      final String targetId = conn['ConnectedUserId'] ?? '';
      final bool canRemove = _canRemove(targetRole, targetId);
      final String name = conn['ConnectedUserName'] ?? 'Unknown';
      final String connectionId = conn['ConnectionId'] ?? '';

      return Card(
        elevation: isElderly ? 4 : 0, // High-contrast for elderly
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: isElderly ? const BorderSide(color: Color(0xFF2563EB), width: 2) : BorderSide.none,
        ),
        margin: const EdgeInsets.only(bottom: 12),
        child: ListTile(
          contentPadding: EdgeInsets.all(isElderly ? 16.0 : 8.0),
          leading: CircleAvatar(
            radius: isElderly ? 28 : 20,
            backgroundColor: targetRole == 'caregiver' ? const Color(0xFFEFF6FF) : const Color(0xFFFEF2F2),
            child: Icon(
              targetRole == 'caregiver' ? Icons.medical_services : Icons.family_restroom, 
              color: targetRole == 'caregiver' ? const Color(0xFF2563EB) : const Color(0xFFEF4444),
              size: isElderly ? 28 : 20,
            ),
          ),
          title: Text(
            name, 
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: isElderly ? 20 : 16)
          ),
          subtitle: Text(
            targetRole.toUpperCase(), 
            style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold)
          ),
          trailing: canRemove
              ? IconButton(
                  icon: Icon(Icons.remove_circle, color: const Color(0xFFEF4444), size: isElderly ? 32 : 24),
                  onPressed: () => _confirmDelete(context, connectionId, name, targetRole),
                )
              : null,
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A)),
          onPressed: onBack,
        ),
        title: Text(isElderly ? 'My Care Network' : 'Care Team Directory', style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w900)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
  padding: const EdgeInsets.all(20),
  children: [
    if (!isElderly) ...[
      const Text('ACTIVE SENIOR PATIENT', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF64748B), letterSpacing: 1.0)),
      const SizedBox(height: 10),
      Card(
        elevation: 0,
        color: const Color(0xFFEFF6FF),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFFBFDBFE), width: 2),
        ),
        margin: const EdgeInsets.only(bottom: 24),
        child: ListTile(
          contentPadding: const EdgeInsets.all(16.0),
          leading: const CircleAvatar(
            radius: 28,
            backgroundColor: Color(0xFF2563EB),
            child: Icon(Icons.elderly, color: Colors.white, size: 28),
          ),
          title: const Text('Linked Patient', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF1E3A8A))),
          subtitle: const Text('Primary Care Focus', style: TextStyle(color: Color(0xFF3B82F6), fontWeight: FontWeight.bold)),
        ),
      ),
      const Text('To prevent duplicated care tasks, collaborate with active members below.', style: TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w500)),
      const SizedBox(height: 20),
    ],
    const Text('CAREGIVERS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF64748B), letterSpacing: 1.0)),
          const SizedBox(height: 10),
          if (caregivers.isEmpty) 
            const Text('No caregivers assigned.', style: TextStyle(color: Color(0xFF94A3B8), fontStyle: FontStyle.italic)),
          ...caregivers.map((c) => _buildConnectionCard(c, 'caregiver')).toList(),

          const SizedBox(height: 24),
          const Text('FAMILY MEMBERS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF64748B), letterSpacing: 1.0)),
          const SizedBox(height: 10),
          if (familyMembers.isEmpty) 
            const Text('No family members linked.', style: TextStyle(color: Color(0xFF94A3B8), fontStyle: FontStyle.italic)),
          ...familyMembers.map((f) => _buildConnectionCard(f, 'family')).toList(),
        ],
      ),
    );
  }
}