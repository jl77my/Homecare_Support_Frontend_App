import 'package:flutter_test/flutter_test.dart';
import 'package:homecare_app/core/models/models.dart';

void main() {
  test('parses a ready health prediction returned by the backend', () {
    final prediction = HealthPrediction.fromJson({
      'modelInfo': {
        'modelReady': true,
        'minimumRecords': 5,
        'recordsAnalyzed': 6,
      },
      'riskLevel': 'moderate',
      'riskScore': 42,
      'stabilityScore': 58,
      'isAnomaly': true,
      'summary': 'The latest readings differ from the personal baseline.',
      'clinicalAlerts': ['Latest blood pressure is in the configured high range.'],
      'recommendations': ['Repeat the measurement and continue monitoring.'],
      'metrics': [
        {
          'key': 'systolic',
          'label': 'Systolic pressure',
          'latest': 145,
          'unit': 'mmHg',
          'baselineMean': 121.2,
          'deviationFromBaseline': 2.8,
          'trend': 'increasing',
          'nextReadingEstimate': 147,
          'abnormal': false,
        },
      ],
      'disclaimer': 'This screening result supports monitoring only.',
    });

    expect(prediction.modelReady, isTrue);
    expect(prediction.riskLevel, 'moderate');
    expect(prediction.stabilityScore, 58);
    expect(prediction.metrics.single.trend, 'increasing');
    expect(prediction.clinicalAlerts, hasLength(1));
  });
}
