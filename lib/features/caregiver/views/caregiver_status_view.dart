import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/models.dart';
import '../providers/caregiver_provider.dart';

class CaregiverStatusView extends ConsumerStatefulWidget {
  final VoidCallback onNavigateToReports;
  final String patientId;

  const CaregiverStatusView({
    super.key,
    required this.onNavigateToReports,
    this.patientId = "00000000-0000-0000-0000-000000000000",
  });

  @override
  ConsumerState<CaregiverStatusView> createState() => _CaregiverStatusViewState();
}

class _CaregiverStatusViewState extends ConsumerState<CaregiverStatusView> {
  final _heartRateController = TextEditingController();
  final _bpController = TextEditingController();
  final _glucoseController = TextEditingController();

  @override
  void dispose() {
    _heartRateController.dispose();
    _bpController.dispose();
    _glucoseController.dispose();
    super.dispose();
  }

  Future<void> _saveVitals() async {
    final hrStr = _heartRateController.text.trim();
    final bp = _bpController.text.trim();
    final glucoseStr = _glucoseController.text.trim();

    if (hrStr.isEmpty || bp.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter Heart Rate and Blood Pressure.')),
      );
      return;
    }

    final success = await ref.read(caregiverProvider.notifier).recordHealth(
          patientId: widget.patientId,
          heartRate: hrStr,
          bloodPressure: bp,
          bloodSugar: glucoseStr.isEmpty ? '120' : glucoseStr,
          notes: 'Routine health entry',
        );

    if (success && mounted) {
      _heartRateController.clear();
      _bpController.clear();
      _glucoseController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vitals logged successfully & synchronized with family!'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
    } else if (mounted) {
      final error = ref.read(caregiverProvider).errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error ?? 'Failed to log vitals.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final caregiverState = ref.watch(caregiverProvider);
    final latest = caregiverState.vitals.isNotEmpty
        ? caregiverState.vitals.first
        : HealthVitals(
            id: '',
            heartRate: 72,
            bloodPressure: '120/80',
            glucose: 100,
            timestamp: DateTime.now(),
            recordedBy: 'Caregiver',
          );

    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        // Active Monitoring Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: const Color(0xFFF1F5F9)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0A000000),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Active Monitoring',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'LIVE',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF15803D)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFF1F5F9)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.favorite, size: 14, color: Color(0xFF94A3B8)),
                              SizedBox(width: 4),
                              Text(
                                'HEART RATE',
                                style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Color(0xFF94A3B8)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                '${latest.heartRate}',
                                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                              ),
                              const SizedBox(width: 4),
                              const Text(
                                'BPM',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF94A3B8)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFF1F5F9)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.show_chart, size: 14, color: Color(0xFF94A3B8)),
                              SizedBox(width: 4),
                              Text(
                                'BLOOD PRESSURE',
                                style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Color(0xFF94A3B8)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            latest.bloodPressure,
                            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Log New Vitals Form
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(36),
            boxShadow: const [
              BoxShadow(
                color: Color(0x25000000),
                blurRadius: 20,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.add_circle_outline, color: Colors.white, size: 22),
                  SizedBox(width: 8),
                  Text(
                    'Log New Vitals',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildVitalsInputField(
                      controller: _heartRateController,
                      label: 'HEART RATE',
                      hint: '72',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildVitalsInputField(
                      controller: _bpController,
                      label: 'PRESSURE',
                      hint: '120/80',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildVitalsInputField(
                controller: _glucoseController,
                label: 'GLUCOSE LEVEL (OPTIONAL)',
                hint: '95',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: caregiverState.isLoading ? null : _saveVitals,
                  icon: caregiverState.isLoading
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.check, size: 20),
                  label: const Text('SUBMIT RECORDS', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                    style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Care Reports Shortcut Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: const Color(0xFFF1F5F9)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.file_present_rounded, color: Color(0xFF2563EB), size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Care Reports & Photo Logs',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Write new report with photo attachments',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: widget.onNavigateToReports,
                icon: const Icon(Icons.arrow_forward_ios, size: 16, color: Color(0xFF94A3B8)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVitalsInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white54, letterSpacing: 0.8),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white38, fontSize: 16),
            filled: true,
            fillColor: Colors.white.withOpacity(0.1),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 2),
            ),
          ),
        ),
      ],
    );
  }
}