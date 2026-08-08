import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';

class AccountSettingsView extends ConsumerStatefulWidget {
  const AccountSettingsView({super.key});

  @override
  ConsumerState<AccountSettingsView> createState() => _AccountSettingsViewState();
}

class _AccountSettingsViewState extends ConsumerState<AccountSettingsView> {
  bool _isEditing = false;
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  String _selectedGender = 'Prefer not to say';

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).user;
    _nameController = TextEditingController(text: user?.name ?? '');
    _phoneController = TextEditingController(text: '-');
    _emailController = TextEditingController(text: user?.email ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _showChangePasswordModal() {
    final currentPassController = TextEditingController();
    final newPassController = TextEditingController();
    final confirmPassController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Change Password', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
            const SizedBox(height: 16),
            TextField(controller: currentPassController, obscureText: true, decoration: const InputDecoration(labelText: 'Current Password')),
            const SizedBox(height: 12),
            TextField(controller: newPassController, obscureText: true, decoration: const InputDecoration(labelText: 'New Password')),
            const SizedBox(height: 12),
            TextField(controller: confirmPassController, obscureText: true, decoration: const InputDecoration(labelText: 'Confirm Password')),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password updated successfully!')));
                },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), padding: const EdgeInsets.symmetric(vertical: 16)),
                child: const Text('UPDATE PASSWORD', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Account Settings', style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w900)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Profile Photo Avatar with Edit Badge
          Center(
            child: Stack(
              children: [
                const CircleAvatar(
                  radius: 50,
                  backgroundColor: Color(0xFF0F172A),
                  child: Icon(Icons.person, size: 50, color: Colors.white),
                ),
                if (_isEditing)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: const Color(0xFF2563EB),
                      child: IconButton(
                        icon: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                        onPressed: () {},
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Full Name
          TextField(
            controller: _nameController,
            enabled: _isEditing,
            decoration: const InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.person_outline)),
          ),
          const SizedBox(height: 16),

          // Phone Number (+60)
          TextField(
            controller: _phoneController,
            enabled: _isEditing,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(labelText: 'Phone Number', prefixIcon: Icon(Icons.phone_outlined)),
          ),
          const SizedBox(height: 16),

          // Read-Only Email Address
          TextField(
            controller: _emailController,
            enabled: false,
            decoration: const InputDecoration(
              labelText: 'Email Address (Read-Only)',
              prefixIcon: Icon(Icons.email_outlined),
              filled: true,
              fillColor: Color(0xFFF1F5F9),
            ),
          ),
          const SizedBox(height: 16),

          // Gender Selection Dropdown
          DropdownButtonFormField<String>(
            value: _selectedGender,
            decoration: const InputDecoration(labelText: 'Gender', prefixIcon: Icon(Icons.wc)),
            items: ['Male', 'Female', 'Prefer not to say'].map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
            onChanged: _isEditing ? (val) => setState(() => _selectedGender = val!) : null,
          ),
          const SizedBox(height: 24),

          // Change Password Sub-Screen Modal Trigger
          ListTile(
            tileColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Color(0xFFE2E8F0))),
            leading: const Icon(Icons.lock_outline, color: Color(0xFF2563EB)),
            title: const Text('Change Password', style: TextStyle(fontWeight: FontWeight.bold)),
            trailing: const Icon(Icons.chevron_right),
            onTap: _showChangePasswordModal,
          ),
          const SizedBox(height: 12),

          // Privacy Policy & Terms Modal
          ListTile(
            tileColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Color(0xFFE2E8F0))),
            leading: const Icon(Icons.privacy_tip_outlined, color: Color(0xFF2563EB)),
            title: const Text('Privacy Policy & Terms & Conditions', style: TextStyle(fontWeight: FontWeight.bold)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Privacy Policy & Terms'),
                  content: const SingleChildScrollView(
                    child: Text('HomeCare is committed to protecting user health data and privacy in accordance with PDPA guidelines...'),
                  ),
                  actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('CLOSE'))],
                ),
              );
            },
          ),
          const SizedBox(height: 32),

          // Action Buttons: Edit Profile / Save Changes
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                setState(() => _isEditing = !_isEditing);
                if (!_isEditing) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile saved successfully!')));
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _isEditing ? const Color(0xFF22C55E) : const Color(0xFF2563EB),
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: Text(
                _isEditing ? 'SAVE CHANGES' : 'EDIT PROFILE',
                style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}