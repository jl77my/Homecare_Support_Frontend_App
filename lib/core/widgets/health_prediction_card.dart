import 'package:flutter/material.dart';
import '../models/models.dart';

class HealthPredictionCard extends StatelessWidget {
  const HealthPredictionCard({super.key, required this.prediction});

  final HealthPrediction? prediction;

  @override
  Widget build(BuildContext context) {
    final data = prediction;
    if (data == null) {
      return _shell(
        child: const Row(
          children: [
            SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
            SizedBox(width: 12),
            Expanded(child: Text('Preparing health trend analysis...')),
          ],
        ),
      );
    }

    final colors = _riskColors(data.riskLevel);
    return _shell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: colors.background, borderRadius: BorderRadius.circular(16)),
                child: Icon(Icons.auto_graph_rounded, color: colors.foreground, size: 22),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ML HEALTH TREND', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF64748B), letterSpacing: 1)),
                    SizedBox(height: 2),
                    Text('Personalized Prediction', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: colors.background, borderRadius: BorderRadius.circular(14)),
                child: Text(_riskLabel(data.riskLevel), style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: colors.foreground, letterSpacing: 0.5)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(data.summary, style: const TextStyle(fontSize: 12, height: 1.45, color: Color(0xFF475569), fontWeight: FontWeight.w600)),
          const SizedBox(height: 14),
          if (!data.modelReady) _buildTrainingProgress(data, colors) else _buildModelResult(data, colors),
          if (data.clinicalAlerts.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFFECACA))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('READING ALERT', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Color(0xFFB91C1C), letterSpacing: 0.7)),
                  const SizedBox(height: 5),
                  ...data.clinicalAlerts.map((alert) => Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Text('• $alert', style: const TextStyle(fontSize: 11, height: 1.35, color: Color(0xFF991B1B), fontWeight: FontWeight.w600)),
                  )),
                ],
              ),
            ),
          ],
          if (data.recommendations.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.lightbulb_outline, size: 16, color: Color(0xFF075DBB)),
                const SizedBox(width: 7),
                Expanded(child: Text(data.recommendations.first, style: const TextStyle(fontSize: 11, height: 1.4, color: Color(0xFF334155), fontWeight: FontWeight.w600))),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Text(data.disclaimer, style: const TextStyle(fontSize: 9, height: 1.3, color: Color(0xFF94A3B8), fontStyle: FontStyle.italic)),
        ],
      ),
    );
  }

  Widget _buildTrainingProgress(HealthPrediction data, _PredictionColors colors) {
    final target = data.minimumRecords == 0 ? 5 : data.minimumRecords;
    final progress = (data.recordsAnalyzed / target).clamp(0.0, 1.0).toDouble();
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('LEARNING PERSONAL BASELINE', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Color(0xFF64748B))),
              Text('${data.recordsAnalyzed}/$target records', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: colors.foreground)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(value: progress, minHeight: 7, backgroundColor: const Color(0xFFE2E8F0), color: colors.foreground),
          ),
        ],
      ),
    );
  }

  Widget _buildModelResult(HealthPrediction data, _PredictionColors colors) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.background, borderRadius: BorderRadius.circular(16)),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('STABILITY SCORE', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Color(0xFF64748B))),
                    const SizedBox(height: 3),
                    Text('${data.stabilityScore ?? 0}%', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: colors.foreground)),
                  ],
                ),
              ),
              Text('${data.recordsAnalyzed} records analyzed', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
            ],
          ),
        ),
        if (data.metrics.isNotEmpty) ...[
          const SizedBox(height: 10),
          ...data.metrics.map(_metricRow),
        ],
      ],
    );
  }

  Widget _metricRow(HealthMetricPrediction metric) {
    final isChanging = metric.trend != 'stable';
    final color = metric.abnormal ? const Color(0xFFDC2626) : isChanging ? const Color(0xFFD97706) : const Color(0xFF16A34A);
    final icon = metric.trend == 'increasing' ? Icons.trending_up : metric.trend == 'decreasing' ? Icons.trending_down : Icons.trending_flat;
    return Padding(
      padding: const EdgeInsets.only(top: 7),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 7),
          Expanded(child: Text(metric.label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF334155)))),
          Text(metric.trend.toUpperCase(), style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: color, letterSpacing: 0.4)),
          const SizedBox(width: 10),
          SizedBox(
            width: 82,
            child: Text('Next ≈ ${_formatValue(metric.nextReadingEstimate)} ${metric.unit}', textAlign: TextAlign.right, style: const TextStyle(fontSize: 9, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _shell({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 12, offset: Offset(0, 4))],
      ),
      child: child,
    );
  }

  String _formatValue(double value) => value == value.roundToDouble() ? value.toInt().toString() : value.toStringAsFixed(1);

  String _riskLabel(String risk) {
    switch (risk) {
      case 'high': return 'HIGH ATTENTION';
      case 'moderate': return 'WATCH TREND';
      case 'low': return 'STABLE';
      default: return 'LEARNING';
    }
  }

  _PredictionColors _riskColors(String risk) {
    switch (risk) {
      case 'high': return const _PredictionColors(Color(0xFFFEF2F2), Color(0xFFDC2626));
      case 'moderate': return const _PredictionColors(Color(0xFFFFF7ED), Color(0xFFD97706));
      case 'low': return const _PredictionColors(Color(0xFFF0FDF4), Color(0xFF16A34A));
      default: return const _PredictionColors(Color(0xFFEFF6FF), Color(0xFF075DBB));
    }
  }
}

class _PredictionColors {
  const _PredictionColors(this.background, this.foreground);
  final Color background;
  final Color foreground;
}
