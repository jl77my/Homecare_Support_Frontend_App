import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/models.dart';

/// Reusable version of the family dashboard's live health report design.
class LiveHealthReportCard extends StatelessWidget {
  final HealthVitals? latestVital;

  const LiveHealthReportCard({
    super.key,
    required this.latestVital,
  });

  int get _stability {
    final alertCount = latestVital?.alerts.length ?? 0;
    return (100 - (alertCount * 15)).clamp(0, 100).toInt();
  }

  @override
  Widget build(BuildContext context) {
    final glucose = latestVital?.glucose;
    final glucoseIsHigh = glucose != null && glucose > 140;

    return Semantics(
      container: true,
      label: 'Live health report',
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(36),
          border: Border.all(color: const Color(0xFFF1F5F9)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 16,
              offset: Offset(0, 4),
            ),
          ],
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
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF94A3B8),
                            letterSpacing: 1.2,
                          ),
                        ),
                        if (latestVital != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              'Last updated: ${DateFormat('MMM d, hh:mm a').format(latestVital!.timestamp)}',
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF64748B),
                              ),
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
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.favorite, size: 12, color: Color(0xFFEF4444)),
                        SizedBox(width: 4),
                        Text(
                          'Calibrated',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF64748B),
                          ),
                        ),
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
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final bloodPressureCard = _MetricCard(
                        semanticLabel: 'Blood pressure',
                        label: 'BLOOD PRESSURE',
                        value: latestVital?.bloodPressure ?? '--/--',
                        status: latestVital == null ? 'NO DATA' : 'NORMAL RANGE',
                        backgroundColor: const Color(0xFFF0FDF4),
                        borderColor: const Color(0xFFDCFCE7),
                        labelColor: const Color(0xFF166534),
                        statusBackgroundColor: const Color(0xFF22C55E).withOpacity(0.15),
                        statusColor: const Color(0xFF15803D),
                      );
                      final glucoseCard = _MetricCard(
                        semanticLabel: 'Blood glucose',
                        label: 'GLUCOSE',
                        value: glucose?.toString() ?? '--',
                        status: glucose == null
                            ? 'NO DATA'
                            : glucoseIsHigh
                                ? 'ACTION REQUIRED'
                                : 'OPTIMAL',
                        backgroundColor: glucoseIsHigh
                            ? const Color(0xFFFEF2F2)
                            : const Color(0xFFEFF6FF),
                        borderColor: glucoseIsHigh
                            ? const Color(0xFFFEE2E2)
                            : const Color(0xFFDBEAFE),
                        labelColor: glucoseIsHigh
                            ? const Color(0xFF991B1B)
                            : const Color(0xFF1E40AF),
                        statusBackgroundColor: (glucoseIsHigh
                                ? const Color(0xFFEF4444)
                                : const Color(0xFF3B82F6))
                            .withOpacity(0.15),
                        statusColor: glucoseIsHigh
                            ? const Color(0xFFB91C1C)
                            : const Color(0xFF1D4ED8),
                      );

                      if (constraints.maxWidth < 300) {
                        return Column(
                          children: [
                            bloodPressureCard,
                            const SizedBox(height: 12),
                            glucoseCard,
                          ],
                        );
                      }

                      return Row(
                        children: [
                          Expanded(child: bloodPressureCard),
                          const SizedBox(width: 12),
                          Expanded(child: glucoseCard),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.favorite,
                            color: Color(0xFFF87171),
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'AVG. HEART RATE',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF94A3B8),
                                  letterSpacing: 0.8,
                                ),
                              ),
                              Text(
                                latestVital != null
                                    ? '${latestVital!.heartRate} BPM'
                                    : '-- BPM',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text(
                              'STABILITY',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF94A3B8),
                                letterSpacing: 0.8,
                              ),
                            ),
                            Text(
                              '$_stability%',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: _stability < 80
                                    ? const Color(0xFFEF4444)
                                    : const Color(0xFF4ADE80),
                              ),
                            ),
                          ],
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
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String semanticLabel;
  final String label;
  final String value;
  final String status;
  final Color backgroundColor;
  final Color borderColor;
  final Color labelColor;
  final Color statusBackgroundColor;
  final Color statusColor;

  const _MetricCard({
    required this.semanticLabel,
    required this.label,
    required this.value,
    required this.status,
    required this.backgroundColor,
    required this.borderColor,
    required this.labelColor,
    required this.statusBackgroundColor,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$semanticLabel: $value. $status',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w900,
                color: labelColor,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                maxLines: 1,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                  letterSpacing: -1,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: statusBackgroundColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  status,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    color: statusColor,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
