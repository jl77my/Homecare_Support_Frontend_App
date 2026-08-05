import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/elderly_provider.dart';

class PairingCodeModal extends ConsumerStatefulWidget {
  const PairingCodeModal({super.key});

  @override
  ConsumerState<PairingCodeModal> createState() => _PairingCodeModalState();
}

class _PairingCodeModalState extends ConsumerState<PairingCodeModal> {
  String? _generatedCode;
  bool _isGenerating = false;
  String _selectedRole = 'caregiver';

  Future<void> _handleGenerate() async {
    setState(() => _isGenerating = true);
    final code = await ref.read(elderlyProvider.notifier).generatePairingCode(_selectedRole);
    setState(() {
      _generatedCode = code;
      _isGenerating = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: 28,
        left: 24,
        right: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Generate Invite Code',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 28),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Select who you want to invite, then share the 6-character code with them.',
            style: TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.4),
          ),
          const SizedBox(height: 20),

          // Role Target Selector Segment
          Row(
            children: [
              Expanded(
                child: ChoiceChip(
                  label: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text('Caregiver Code', style: TextStyle(fontWeight: FontWeight.w800)),
                  ),
                  selected: _selectedRole == 'caregiver',
                  onSelected: (_) => setState(() {
                    _selectedRole = 'caregiver';
                    _generatedCode = null;
                  }),
                  selectedColor: const Color(0xFF2563EB),
                  labelStyle: TextStyle(color: _selectedRole == 'caregiver' ? Colors.white : const Color(0xFF0F172A)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ChoiceChip(
                  label: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text('Family Code', style: TextStyle(fontWeight: FontWeight.w800)),
                  ),
                  selected: _selectedRole == 'family',
                  onSelected: (_) => setState(() {
                    _selectedRole = 'family';
                    _generatedCode = null;
                  }),
                  selectedColor: const Color(0xFF2563EB),
                  labelStyle: TextStyle(color: _selectedRole == 'family' ? Colors.white : const Color(0xFF0F172A)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Display Generated Code
          if (_generatedCode != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 32),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFF2563EB), width: 2),
              ),
              child: Column(
                children: [
                  const Text(
                    'SHARE THIS CODE:',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF94A3B8), letterSpacing: 1.2),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _generatedCode!,
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF2563EB),
                      letterSpacing: 4,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Valid for 24 hours',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF10B981)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Generate Action Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isGenerating ? null : _handleGenerate,
              icon: _isGenerating
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.qr_code),
              label: Text(
                _generatedCode == null ? 'GENERATE CODE NOW' : 'GENERATE NEW CODE',
                style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.5),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F172A),
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