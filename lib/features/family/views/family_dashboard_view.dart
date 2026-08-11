// lib/features/family/views/family_dashboard_view.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/widgets/health_prediction_card.dart';
import '../providers/family_provider.dart';
import 'family_pairing_view.dart';

class FamilyDashboardView extends ConsumerStatefulWidget {
  final VoidCallback onNavigateToReports;
  const FamilyDashboardView({
    super.key,
    required this.onNavigateToReports,
  });

  @override
  ConsumerState<FamilyDashboardView> createState() => _FamilyDashboardViewState();
}

class _FamilyDashboardViewState extends ConsumerState<FamilyDashboardView> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(familyDashboardProvider.notifier).fetchLinkedSeniors());
  }

  @override
  Widget build(BuildContext context) {
    final familyState = ref.watch(familyDashboardProvider);
    final latestVital = familyState.latestVital;
    final latestMsg = familyState.latestMessage;
    final latestReport = familyState.latestReport;
    final linkedSeniors = familyState.linkedSeniors;
    final selectedElderlyId = familyState.selectedElderlyId;

    
    if (familyState.isLoading && linkedSeniors.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (linkedSeniors.isEmpty) {
      return ListView(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 8),
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(36),
              border: Border.all(color: const Color(0xFFE2E8F0), width: 2),
              boxShadow: const [
                BoxShadow(color: Color(0x0F000000), blurRadius: 16, offset: Offset(0, 4)),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFBFDBFE), width: 2),
                  ),
                  child: const Icon(Icons.family_restroom, size: 56, color: Color(0xFF2563EB)),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Welcome to HomeCare',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Link your senior family member using their 6-character invitation code to view live vitals, daily care reports, and caregiver updates.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.5),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(MaterialPageRoute(builder: (context) => const FamilyPairingView()));
                    },
                    icon: const Icon(Icons.qr_code_scanner, size: 20),
                    label: const Text('ENTER PAIRING CODE NOW', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.5)),
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
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              const Icon(Icons.person_search_outlined, color: Color(0xFF60A5FA), size: 20),
              const SizedBox(width: 8),
              const Text(
                'MONITORING:',
                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.8),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: linkedSeniors.any((s) => s['elderlyId'] == selectedElderlyId)
                        ? selectedElderlyId
                        : linkedSeniors.first['elderlyId'],
                    dropdownColor: const Color(0xFF1E293B),
                    isExpanded: true,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                    items: linkedSeniors.map((senior) {
                      return DropdownMenuItem<String>(
                        value: senior['elderlyId'],
                        child: Text(senior['name'] ?? 'Senior User', overflow: TextOverflow.ellipsis),
                      );
                    }).toList(),
                    onChanged: (newElderlyId) {
                      if (newElderlyId != null) {
                        ref.read(familyDashboardProvider.notifier).switchElderlyContext(newElderlyId);
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(36),
            border: Border.all(color: const Color(0xFFF1F5F9)),
            boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 16, offset: Offset(0, 4))],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: const BoxDecoration(
                  color: Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'LIVE HEALTH REPORT',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF94A3B8), letterSpacing: 1.2),
                          ),
                          if (latestVital != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                'Last updated: ${DateFormat('MMM d, hh:mm a').format(latestVital.timestamp)}',
                                style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.favorite, size: 12, color: Color(0xFFEF4444)),
                          SizedBox(width: 4),
                          Text('Calibrated', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0FDF4),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: const Color(0xFFDCFCE7)),
                            ),
                            child: Column(
                              children: [
                                const Text('BLOOD PRESSURE', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Color(0xFF166534), letterSpacing: 0.8)),
                                const SizedBox(height: 6),
                                Text(latestVital?.bloodPressure ?? '--/--', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Color(0xFF0F172A), letterSpacing: -1)),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(color: const Color(0xFF22C55E).withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                                  child: const Text('NORMAL RANGE', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: Color(0xFF15803D))),
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
                              color: (latestVital?.glucose ?? 100) > 140 ? const Color(0xFFFEF2F2) : const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: (latestVital?.glucose ?? 100) > 140 ? const Color(0xFFFEE2E2) : const Color(0xFFDBEAFE)),
                            ),
                            child: Column(
                              children: [
                                Text('GLUCOSE', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: (latestVital?.glucose ?? 100) > 140 ? const Color(0xFF991B1B) : const Color(0xFF1E40AF), letterSpacing: 0.8)),
                                const SizedBox(height: 6),
                                Text(latestVital != null ? '${latestVital.glucose}' : '--', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Color(0xFF0F172A), letterSpacing: -1)),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: ((latestVital?.glucose ?? 100) > 140 ? const Color(0xFFEF4444) : const Color(0xFF3B82F6)).withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    (latestVital?.glucose ?? 100) > 140 ? 'ACTION REQUIRED' : 'OPTIMAL',
                                    style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: (latestVital?.glucose ?? 100) > 140 ? const Color(0xFFB91C1C) : const Color(0xFF1D4ED8)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(24)),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
                            child: const Icon(Icons.favorite, color: Color(0xFFF87171), size: 22),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('AVG. HEART RATE', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Color(0xFF94A3B8), letterSpacing: 0.8)),
                                Text(latestVital != null ? '${latestVital.heartRate} BPM' : '-- BPM', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white)),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                                                     ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        HealthPredictionCard(prediction: familyState.healthPrediction),
        const SizedBox(height: 20),
        if (latestReport != null)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: const Color(0xFFF1F5F9)),
              boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 12, offset: Offset(0, 4))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.assignment_outlined, color: Color(0xFF2563EB), size: 20),
                        const SizedBox(width: 8),
                        Text('Latest Care Report (${familyState.totalReportsCount})', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                      ],
                    ),
                    TextButton(onPressed: widget.onNavigateToReports, child: const Text('View All', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFF1F5F9))),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(10)),
                            child: Text('${latestReport.category.label.toUpperCase()} ${latestReport.category.emoji}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF15803D))),
                          ),
                          const Spacer(),
                          Text(DateFormat('MMM d   hh:mm a').format(latestReport.timestamp), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF94A3B8))),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(latestReport.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                      const SizedBox(height: 4),
                      Text(latestReport.text, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.4)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 20),
        if (latestMsg != null)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.chat_bubble_outline, color: Color(0xFF2563EB), size: 18),
                    SizedBox(width: 8),
                    Text('LATEST UPDATE FROM CAREGIVER', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF0F172A), letterSpacing: 1.0)),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFF1F5F9))),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: const Color(0xFF3B82F6),
                        child: Text(
                          latestMsg.senderId.isNotEmpty ? latestMsg.senderId.toUpperCase().substring(0, 1) : 'C',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Caregiver', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF94A3B8))),
                            const SizedBox(height: 2),
                            Text(latestMsg.text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
