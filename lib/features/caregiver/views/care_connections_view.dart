// lib/features/caregiver/views/care_connections_view.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import '../../auth/providers/auth_provider.dart';
import '../../family/providers/family_provider.dart';
import '../../caregiver/providers/caregiver_provider.dart';
import '../../elderly/providers/elderly_provider.dart';

class CareConnectionsView extends ConsumerStatefulWidget {
  final VoidCallback onBack;
  const CareConnectionsView({super.key, required this.onBack});

  @override
  ConsumerState<CareConnectionsView> createState() => _CareConnectionsViewState();
}

class _CareConnectionsViewState extends ConsumerState<CareConnectionsView> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final user = ref.read(authProvider).user;
      if (user == null) return;
      final role = user.role.toLowerCase();
      
      // Request fresh global directory fetch
      if (role == 'elderly') {
        ref.read(elderlyProvider.notifier).fetchCareConnections();
      } else if (role == 'caregiver') {
        ref.read(caregiverProvider.notifier).fetchCareConnections(); 
      } else if (role == 'family') {
        ref.read(familyDashboardProvider.notifier).fetchCareConnections();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    if (user == null) return const SizedBox.shrink();
    
    final role = user.role.toLowerCase();
    final isElderly = role == 'elderly';

    List<dynamic> elderlyList = [];
    List<dynamic> caregivers = [];
    List<dynamic> familyMembers = [];
    bool isLoading = false;

    // Reactively watch providers directly
    if (isElderly) {
      final state = ref.watch(elderlyProvider);
      caregivers = state.activeCaregivers;
      familyMembers = state.activeFamilyMembers;
      isLoading = state.isLoading;
    } else if (role == 'caregiver') {
      final state = ref.watch(caregiverProvider);
      elderlyList = state.assignedSeniors;
      caregivers = state.activeCaregivers;
      familyMembers = state.activeFamilyMembers;
      isLoading = state.isLoading;
    } else if (role == 'family') {
      final state = ref.watch(familyDashboardProvider);
      elderlyList = state.linkedSeniors;
      caregivers = state.activeCaregivers;
      familyMembers = state.activeFamilyMembers;
      isLoading = state.isLoading;
    }

    bool canRemove(String targetRole, String targetUserId) {
      if (isElderly) return true; 
      if (role == 'family') return targetRole == 'caregiver' || targetUserId == user.id || targetRole == 'elderly'; 
      if (role == 'caregiver') return targetUserId == user.id || targetRole == 'elderly'; 
      return false;
    }

    void confirmDelete(BuildContext context, String connectionId, String name, String targetRole) {
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
                if (isElderly) {
                  ref.read(elderlyProvider.notifier).deleteCareConnection(connectionId);
                } else if (role == 'family') {
                  ref.read(familyDashboardProvider.notifier).deleteCareConnection(connectionId);
                } else if (role == 'caregiver') {
                  ref.read(caregiverProvider.notifier).deleteCareConnection(connectionId);
                }
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$name removed from care connections.'), backgroundColor: const Color(0xFF10B981)));
              },
              child: const Text('REMOVE', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }

    Widget buildConnectionCard(dynamic conn, String targetRole) {
      final String targetId = (conn['ConnectedUserId'] ?? conn['elderlyId'] ?? '').toString();
      final String name = (conn['ConnectedUserName'] ?? conn['name'] ?? 'Unknown').toString();
      final String connectionId = (conn['ConnectionId'] ?? conn['connectionId'] ?? '').toString();
      final String photoUrl = (conn['ProfilePhotoUrl'] ?? conn['profilePhotoUrl'] ?? '').toString();

      return Card(
        elevation: isElderly ? 4 : 0, 
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: isElderly ? const BorderSide(color: Color(0xFF2563EB), width: 2) : BorderSide.none,
        ),
        margin: const EdgeInsets.only(bottom: 12),
        child: ListTile(
          contentPadding: EdgeInsets.all(isElderly ? 16.0 : 8.0),
          leading: CircleAvatar(
            radius: isElderly ? 28 : 20,
            backgroundColor: targetRole == 'caregiver' ? const Color(0xFFEFF6FF) : (targetRole == 'elderly' ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2)),
            backgroundImage: (photoUrl.isNotEmpty)
                ? (photoUrl.startsWith('data:image') ? MemoryImage(base64Decode(photoUrl.split(',')[1])) : NetworkImage(photoUrl)) as ImageProvider
                : null,
            child: photoUrl.isEmpty
                ? Icon(
                    targetRole == 'caregiver' ? Icons.medical_services : (targetRole == 'elderly' ? Icons.elderly : Icons.family_restroom), 
                    color: targetRole == 'caregiver' ? const Color(0xFF2563EB) : (targetRole == 'elderly' ? const Color(0xFF16A34A) : const Color(0xFFEF4444)),
                    size: isElderly ? 28 : 20,
                  )
                : null,
          ),
          title: Text(name, style: TextStyle(fontWeight: FontWeight.w900, fontSize: isElderly ? 20 : 16)),
          subtitle: Text(targetRole.toUpperCase(), style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
          trailing: (canRemove(targetRole, targetId) && connectionId.isNotEmpty)
              ? IconButton(
                  icon: Icon(Icons.remove_circle, color: const Color(0xFFEF4444), size: isElderly ? 32 : 24),
                  onPressed: () => confirmDelete(context, connectionId, name, targetRole),
                )
              : null,
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A)), onPressed: widget.onBack),
        title: Text(isElderly ? 'My Care Network' : 'Care Team Directory', style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w900)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: isLoading 
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                if (isElderly) ...[
                  const Text('ASSIGNED CAREGIVERS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF64748B), letterSpacing: 1.0)),
                  const SizedBox(height: 10),
                  if (caregivers.isEmpty)
                     const Text('No caregivers assigned.', style: TextStyle(color: Color(0xFF94A3B8), fontStyle: FontStyle.italic)),
                  ...caregivers.map((c) => buildConnectionCard(c, 'caregiver')),
                  const SizedBox(height: 24),
                  const Text('LINKED FAMILY MEMBERS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF64748B), letterSpacing: 1.0)),
                  const SizedBox(height: 10),
                  if (familyMembers.isEmpty)
                     const Text('No family members linked.', style: TextStyle(color: Color(0xFF94A3B8), fontStyle: FontStyle.italic)),
                  ...familyMembers.map((f) => buildConnectionCard(f, 'family')),
                ] 
                else if (role == 'caregiver') ...[
                  const Text('ASSIGNED SENIORS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF64748B), letterSpacing: 1.0)),
                  const SizedBox(height: 10),
                  if (elderlyList.isEmpty)
                     const Text('No seniors assigned.', style: TextStyle(color: Color(0xFF94A3B8), fontStyle: FontStyle.italic)),
                  ...elderlyList.map((e) => buildConnectionCard(e, 'elderly')),
                  const SizedBox(height: 24),
                  const Text('LINKED FAMILY MEMBERS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF64748B), letterSpacing: 1.0)),
                  const SizedBox(height: 10),
                  if (familyMembers.isEmpty)
                     const Text('No family members linked to your assigned seniors.', style: TextStyle(color: Color(0xFF94A3B8), fontStyle: FontStyle.italic)),
                  ...familyMembers.map((f) => buildConnectionCard(f, 'family')),
                ]
                else if (role == 'family') ...[
                  const Text('LINKED SENIORS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF64748B), letterSpacing: 1.0)),
                  const SizedBox(height: 10),
                  if (elderlyList.isEmpty)
                     const Text('No seniors linked.', style: TextStyle(color: Color(0xFF94A3B8), fontStyle: FontStyle.italic)),
                  ...elderlyList.map((e) => buildConnectionCard(e, 'elderly')),
                  const SizedBox(height: 24),
                  const Text('ASSIGNED CAREGIVERS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF64748B), letterSpacing: 1.0)),
                  const SizedBox(height: 10),
                  if (caregivers.isEmpty)
                     const Text('No caregivers assigned to your linked seniors.', style: TextStyle(color: Color(0xFF94A3B8), fontStyle: FontStyle.italic)),
                  ...caregivers.map((c) => buildConnectionCard(c, 'caregiver')),
                ],
              ],
            ),
    );
  }
}