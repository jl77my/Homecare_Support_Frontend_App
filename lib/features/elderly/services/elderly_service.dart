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

  // 1. Check if Elderly User has active Caregiver or Family links
  Future<bool> checkPairingStatus(String token) async {
    try {
      final response = await _client.get(
        Uri.parse('$_baseUrl/pairing/status'),
        headers: _headers(token),
      );
      final data = _parseResponse(response);
      return (data['isLinked'] as bool?) ?? false;
    } catch (_) {
      return false;
    }
  }

  // 2. Fetch Scheduled Medications
  Future<List<dynamic>> getMedications(String token) async {
    final response = await _client.get(
      Uri.parse('$_baseUrl/elderly/medications'),
      headers: _headers(token),
    );
    final data = _parseResponse(response);
    return data['medications'] as List<dynamic>? ?? [];
  }

  // 3. Confirm Medication Intake
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

  // 4. Log Mood
  Future<Map<String, dynamic>> logMood({
    required String token,
    required String mood,
  }) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/elderly/mood'),
      headers: _headers(token),
      body: jsonEncode({'mood': mood}),
    );
    return _parseResponse(response);
  }

  // 5. Trigger SOS Alert
  Future<Map<String, dynamic>> triggerSos({required String token}) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/elderly/sos'),
      headers: _headers(token),
      body: jsonEncode({}),
    );
    return _parseResponse(response);
  }

  // 6. Generate Temporary Pairing Code
  Future<Map<String, dynamic>> generatePairingCode({
    required String token,
    required String roleTarget,
  }) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/pairing/generate'),
      headers: _headers(token),
      body: jsonEncode({'roleTarget': roleTarget}),
    );
    return _parseResponse(response);
  }

  // 7. Fetch Care Connections
  Future<Map<String, dynamic>> getCareConnections(String token) async {
    final response = await _client.get(
      Uri.parse('$_baseUrl/user/care-connections'),
      headers: _headers(token),
    );
    return _parseResponse(response);
  }

  // 8. Delete / Unlink Care Connection (Elderly has full permission to delete any link)
  Future<void> deleteCareConnection(String token, String connectionId) async {
    final response = await _client.delete(
      Uri.parse('$_baseUrl/user/care-connections/$connectionId'),
      headers: _headers(token),
    );
    _parseResponse(response);
  }

  Map<String, dynamic> _parseResponse(http.Response response) {
    final decoded = jsonDecode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded is Map<String, dynamic> ? decoded : {'data': decoded};
    }
    throw Exception(decoded['message'] ?? decoded['error'] ?? 'Request failed');
  }
}