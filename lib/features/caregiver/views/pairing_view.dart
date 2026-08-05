import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/caregiver_provider.dart';

class PairingView extends ConsumerStatefulWidget {
  const PairingView({super.key});

  @override
  ConsumerState<PairingView> createState() => _PairingViewState();
}

class _PairingViewState extends ConsumerState<PairingView> {
  final _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _submitCode() async {
    final code = _codeController.text.trim();
    if (code.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid 6-character pairing code.')),
      );
      return;
    }

    final success = await ref.read(caregiverProvider.notifier).pairWithElderly(code);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Successfully linked with senior patient!'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
      Navigator.of(context).pop();
    } else if (mounted) {
      final error = ref.read(caregiverProvider).errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error ?? 'Failed to process pairing code.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(caregiverProvider).isLoading;

    return Scaffold(
      backgroundColor: const Color(0xFF171717),
      appBar: AppBar(
        title: const Text('Link Senior Patient', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF262626),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.qr_code_scanner, color: Color(0xFF3B82F6), size: 64),
            const SizedBox(height: 16),
            const Text(
              'Enter Senior Pairing Code',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            const Text(
              'Ask the senior or family member for their 6-digit invitation code.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFFA3A3A3), fontSize: 13),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _codeController,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 24, letterSpacing: 4, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                hintText: 'HC-8921',
                hintStyle: const TextStyle(color: Color(0xFF525252), fontSize: 20),
                filled: true,
                fillColor: const Color(0xFF262626),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: isLoading ? null : _submitCode,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: isLoading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('LINK SENIOR PATIENT NOW', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}