// lib/features/caregiver/views/profile_view.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import '../../auth/providers/auth_provider.dart';
import '../../elderly/widgets/pairing_code_modal.dart';
import '../../family/views/family_pairing_view.dart';
import 'account_settings_view.dart';
import 'care_connections_view.dart';
import 'pairing_view.dart';

class ProfileView extends ConsumerWidget {
  final VoidCallback? onNavigateToAccountSettings;
  final VoidCallback? onNavigateToCareConnections; // Added navigation callback

  const ProfileView({
    super.key,
    this.onNavigateToAccountSettings,
    this.onNavigateToCareConnections,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    if (user == null) {
      return const Center(
        child: Text(
          'No active user session.',
          style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
        ),
      );
    }

    final role = user.role.toLowerCase();
    final isElderly = role == 'elderly';
    final isCaregiver = role == 'caregiver';
    final isFamily = role == 'family';

    return Scaffold(
      backgroundColor: const Color(0xFFF7FBFF),
      appBar: AppBar(
        title: const Text('My Profile', style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w900)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16).copyWith(bottom: 32),
        children: [
          // Profile Header Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(36),
              border: Border.all(color: const Color(0xFFF1F5F9)),
              boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 16, offset: Offset(0, 4))],
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: const Color(0xFFE5F2FF),
                  backgroundImage: user.profilePhotoUrl != null && user.profilePhotoUrl!.startsWith('data:image')
                      ? MemoryImage(base64Decode(user.profilePhotoUrl!.split(',')[1]))
                      : (user.profilePhotoUrl != null ? NetworkImage(user.profilePhotoUrl!) as ImageProvider : null),
                  child: user.profilePhotoUrl == null
                      ? Text(
                          user.name.isNotEmpty ? user.name.substring(0, 1).toUpperCase() : 'U',
                          style: const TextStyle(color: Color(0xFF075DBB), fontSize: 32, fontWeight: FontWeight.w900),
                        )
                      : null,
                ),
                const SizedBox(height: 14),
                Text(user.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                const SizedBox(height: 4),
                Text(user.email, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFBFDBFE)),
                  ),
                  child: Text(
                    'ROLE: ${user.role.toUpperCase()}',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF1D4ED8), letterSpacing: 0.8),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Settings & Account Options
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            child: Column(
              children: [
                if (isElderly) ...[
                  ListTile(
                    leading: const Icon(Icons.qr_code_2, color: Color(0xFF075DBB)),
                    title: const Text('Generate Invitation Code', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                    trailing: const Icon(Icons.chevron_right, color: Color(0xFF94A3B8)),
                    onTap: () => showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(36))),
                      builder: (context) => const PairingCodeModal(),
                    ),
                  ),
                  const Divider(height: 1, indent: 60),
                ],
                if (isCaregiver) ...[
                  ListTile(
                    leading: const Icon(Icons.qr_code_scanner, color: Color(0xFF075DBB)),
                    title: const Text('Pair Additional Senior Patient', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                    trailing: const Icon(Icons.chevron_right, color: Color(0xFF94A3B8)),
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => const PairingView())),
                  ),
                  const Divider(height: 1, indent: 60),
                ],
                if (isFamily) ...[
                  ListTile(
                    leading: const Icon(Icons.family_restroom, color: Color(0xFF075DBB)),
                    title: const Text('Link Additional Senior Patient', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                    trailing: const Icon(Icons.chevron_right, color: Color(0xFF94A3B8)),
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => const FamilyPairingView())),
                  ),
                  const Divider(height: 1, indent: 60),
                ],
                
                // Account Settings Portal
                ListTile(
                  leading: const Icon(Icons.settings_outlined, color: Color(0xFF075DBB)),
                  title: const Text('Account Settings', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                  trailing: const Icon(Icons.chevron_right, color: Color(0xFF94A3B8)),
                  onTap: () {
                    if (onNavigateToAccountSettings != null) {
                      onNavigateToAccountSettings!();
                    } else {
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => AccountSettingsView(onBack: () => Navigator.pop(context))
                      ));
                    }
                  },
                ),
                const Divider(height: 1, indent: 60),

                // Care Connections Portal (Extracted back to separate view)
                ListTile(
                  leading: const Icon(Icons.diversity_1, color: Color(0xFF075DBB)),
                  title: const Text('Care Connections', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                  trailing: const Icon(Icons.chevron_right, color: Color(0xFF94A3B8)),
                  onTap: () {
                    if (onNavigateToCareConnections != null) {
                      onNavigateToCareConnections!();
                    } else {
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => CareConnectionsView(onBack: () => Navigator.pop(context))
                      ));
                    }
                  },
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => ref.read(authProvider.notifier).logout(),
              icon: const Icon(Icons.logout, color: Color(0xFFEF4444)),
              label: const Text('SIGN OUT', style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.w900)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFEF2F2),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
