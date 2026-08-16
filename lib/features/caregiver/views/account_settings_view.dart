// lib/features/caregiver/views/account_settings_view.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import '../../auth/providers/auth_provider.dart';

class AccountSettingsView extends ConsumerStatefulWidget {
  final VoidCallback onBack;

  const AccountSettingsView({super.key, required this.onBack});

  @override
  ConsumerState<AccountSettingsView> createState() => _AccountSettingsViewState();
}

class _AccountSettingsViewState extends ConsumerState<AccountSettingsView> {
  bool _isEditing = false;
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  String _selectedGender = 'Prefer not to say';
  String? _profilePhotoUrl;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _resetToCurrentData();
  }

  void _resetToCurrentData() {
    final user = ref.read(authProvider).user;
    _nameController = TextEditingController(text: user?.name ?? '');
    _phoneController = TextEditingController(text: user?.phoneNumber ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _selectedGender = user?.gender ?? 'Prefer not to say';
    _profilePhotoUrl = user?.profilePhotoUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _cancelEdit() {
    setState(() {
      _isEditing = false;
    });
    _resetToCurrentData(); // Revert any unsaved typing
  }

  Future<void> _pickImage() async {
    if (!_isEditing) return;
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 30);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _profilePhotoUrl = "data:image/jpeg;base64,${base64Encode(bytes)}";
      });
    }
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
                onPressed: () async {
                  if (newPassController.text != confirmPassController.text) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('New passwords do not match!')));
                    return;
                  }
                  final success = await ref.read(authProvider.notifier).changePassword(
                    currentPassword: currentPassController.text,
                    newPassword: newPassController.text,
                  );
                  if (success && mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password updated successfully!'), backgroundColor: Color(0xFF10B981)));
                  } else if (mounted) {
                    final err = ref.read(authProvider).errorMessage;
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err ?? 'Failed to update password')));
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF075DBB), padding: const EdgeInsets.symmetric(vertical: 16)),
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
    final isLoading = ref.watch(authProvider).isLoading;

    return Scaffold(
      backgroundColor: const Color(0xFFF7FBFF),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A)),
          onPressed: widget.onBack, 
        ),
        title: const Text('Account Settings', style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w900)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: Stack(
              children: [
                GestureDetector(
                  onTap: _pickImage,
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: const Color(0xFFE5F2FF),
                    backgroundImage: _profilePhotoUrl != null && _profilePhotoUrl!.startsWith('data:image')
                        ? MemoryImage(base64Decode(_profilePhotoUrl!.split(',')[1]))
                        : (_profilePhotoUrl != null ? NetworkImage(_profilePhotoUrl!) as ImageProvider : null),
                    child: _profilePhotoUrl == null ? const Icon(Icons.person, size: 50, color: Color(0xFF075DBB)) : null,
                  ),
                ),
                if (_isEditing)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: const Color(0xFF075DBB),
                      child: IconButton(
                        icon: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                        onPressed: _pickImage,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _nameController,
            enabled: _isEditing,
            decoration: const InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.person_outline)),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _phoneController,
            enabled: _isEditing,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(labelText: 'Phone Number', prefixIcon: Icon(Icons.phone_outlined)),
          ),
          const SizedBox(height: 16),
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
          DropdownButtonFormField<String>(
            value: ['Male', 'Female', 'Prefer not to say'].contains(_selectedGender) ? _selectedGender : 'Prefer not to say',
            decoration: const InputDecoration(labelText: 'Gender', prefixIcon: Icon(Icons.wc)),
            items: ['Male', 'Female', 'Prefer not to say'].map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
            onChanged: _isEditing ? (val) => setState(() => _selectedGender = val!) : null,
          ),
          const SizedBox(height: 24),
          
          if (!_isEditing) ...[
            ListTile(
              tileColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Color(0xFFE2E8F0))),
              leading: const Icon(Icons.lock_outline, color: Color(0xFF075DBB)),
              title: const Text('Change Password', style: TextStyle(fontWeight: FontWeight.bold)),
              trailing: const Icon(Icons.chevron_right),
              onTap: _showChangePasswordModal,
            ),
            const SizedBox(height: 12),
          ],
          
          const SizedBox(height: 32),
          
          // --- UPDATED ACTION BUTTONS: CANCEL & SAVE ---
          if (_isEditing)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: isLoading ? null : _cancelEdit,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      side: const BorderSide(color: Color(0xFFEF4444), width: 2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    child: const Text('CANCEL', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFFEF4444))),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: isLoading
                        ? null
                        : () async {
                            final success = await ref.read(authProvider.notifier).updateProfile(
                              name: _nameController.text.trim(),
                              phoneNumber: _phoneController.text.trim(),
                              gender: _selectedGender,
                              profilePhotoUrl: _profilePhotoUrl,
                            );
                            if (success && mounted) {
                              setState(() => _isEditing = false);
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile saved successfully!'), backgroundColor: Color(0xFF10B981)));
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF075DBB),
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    child: isLoading
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('SAVE', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white)),
                  ),
                ),
              ],
            )
          else
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => setState(() => _isEditing = true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF075DBB),
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: const Text('EDIT PROFILE', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 0.8)),
              ),
            ),
        ],
      ),
    );
  }
}
