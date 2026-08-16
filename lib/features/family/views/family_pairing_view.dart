import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/family_provider.dart';
import '../../../core/theme/app_theme.dart';

class FamilyPairingView extends ConsumerStatefulWidget {
  const FamilyPairingView({super.key});

  @override
  ConsumerState<FamilyPairingView> createState() => _FamilyPairingViewState();
}

class _FamilyPairingViewState extends ConsumerState<FamilyPairingView> {
  final _codeController = TextEditingController();
  final _relationshipController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    _relationshipController.dispose();
    super.dispose();
  }

  Future<void> _submitFamilyCode() async {
    final code = _codeController.text.trim();
    final relationship = _relationshipController.text.trim();

    if (code.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid 6-character family pairing code.')),
      );
      return;
    }

    final success = await ref.read(familyDashboardProvider.notifier).linkFamilyByCode(
          code: code,
          relationship: relationship.isEmpty ? 'Family Member' : relationship,
        );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Successfully linked with family senior!'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
      Navigator.of(context).pop();
    } else if (mounted) {
      final error = ref.read(familyDashboardProvider).errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error ?? 'Failed to process family pairing code.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(familyDashboardProvider).isLoading;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Link Family Senior'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.family_restroom, color: Color(0xFF3B82F6), size: 64),
            const SizedBox(height: 16),
            const Text(
              'Enter Family Pairing Code',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.navy, fontSize: 22, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            const Text(
              'Ask your senior family member for their 6-digit family invitation code.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _codeController,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.navy, fontSize: 24, letterSpacing: 4, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                hintText: 'FAM-4921',
                hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 20),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _relationshipController,
              style: const TextStyle(color: AppTheme.navy),
              decoration: InputDecoration(
                labelText: 'Relationship (e.g. Son, Daughter, Spouse)',
                labelStyle: const TextStyle(color: AppTheme.textMuted),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: isLoading ? null : _submitFamilyCode,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: isLoading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('LINK FAMILY MEMBER NOW', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
