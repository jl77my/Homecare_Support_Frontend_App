import 'package:flutter_test/flutter_test.dart';
import 'package:homecare_app/features/agent/models/agent_models.dart';

void main() {
  test('parses an agent answer and confirmation preview', () {
    final response = AgentChatResponse.fromJson({
      'reply': 'I prepared a task for confirmation.',
      'model': 'gemini-3.1-flash-lite',
      'sources': [
        {'id': 'fall', 'title': 'NHS — Falls', 'url': 'https://www.nhs.uk/conditions/falls/'},
      ],
      'action': {
        'token': 'signed-token',
        'expiresInSeconds': 600,
        'preview': {
          'type': 'create_task',
          'title': 'Create task',
          'summary': 'Check blood pressure — due tomorrow',
          'details': 'Record the reading.',
          'patientName': 'Mr Tan',
        },
      },
    });

    expect(response.model, 'gemini-3.1-flash-lite');
    expect(response.sources.single.title, 'NHS — Falls');
    expect(response.action?.preview.type, 'create_task');
    expect(response.action?.preview.patientName, 'Mr Tan');
  });
}
