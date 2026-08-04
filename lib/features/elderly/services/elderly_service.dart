import 'dart:convert';
import 'package:http/http.dart' as http;

class ElderlyService {
  ElderlyService({http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(),
        _baseUrl = baseUrl ??
            const String.fromEnvironment(
              'API_BASE_URL',
              defaultValue: 'http://localhost:3000/api', // 10.0.2.2 for Android Emulator
            );

  final http.Client _client;
  final String _baseUrl;

  Map<String, String> _headers(String token) => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  // 1. Fetch Scheduled Medications for Today
  Future<List<dynamic>> getMedications(String token) async {
    final response = await _client.get(
      Uri.parse('$_baseUrl/elderly/medications'),
      headers: _headers(token),
    );
    final data = _parseResponse(response);
    return data['medications'] as List<dynamic>? ?? [];
  }

  // 2. Confirm Medication Intake
  Future<Map<String, dynamic>> confirmMedication({
    required String token,
    required String medicationId,
    required String status,
  }) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/elderly/medications/confirm'),
      headers: _headers(token),
      body: jsonEncode({
        'medicationId': medicationId,
        'status': status,
      }),
    );
    return _parseResponse(response);
  }

  // 3. Log Daily Mood ('Happy', 'Neutral', 'Sad')
  Future<Map<String, dynamic>> logMood({
    required String token,
    required String mood,
  }) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/elderly/mood'),
      headers: _headers(token),
      body: jsonEncode({
        'mood': mood,
      }),
    );
    return _parseResponse(response);
  }

  // 4. Trigger SOS Emergency Alert
  Future<Map<String, dynamic>> triggerSos({
    required String token,
  }) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/elderly/sos'),
      headers: _headers(token),
      body: jsonEncode({}),
    );
    return _parseResponse(response);
  }

  Map<String, dynamic> _parseResponse(http.Response response) {
    final decoded = jsonDecode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded is Map<String, dynamic> ? decoded : {'data': decoded};
    }
    throw Exception(decoded['message'] ?? decoded['error'] ?? 'Request failed');
  }
}