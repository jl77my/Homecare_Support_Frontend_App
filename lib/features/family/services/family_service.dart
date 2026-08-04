import 'dart:convert';
import 'package:http/http.dart' as http;

class FamilyService {
  FamilyService({http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(),
        _baseUrl = baseUrl ??
            const String.fromEnvironment(
              'API_BASE_URL',
              defaultValue: 'http://localhost:3000/api',
            );

  final http.Client _client;
  final String _baseUrl;

  Map<String, String> _headers(String token) => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  // 1. Monitor Care Tasks
  Future<List<dynamic>> getCareTasks(String token, String patientId) async {
    final response = await _client.get(
      Uri.parse('$_baseUrl/family/tasks/$patientId'),
      headers: _headers(token),
    );
    final data = _parseResponse(response);
    return data['tasks'] as List<dynamic>? ?? [];
  }

  // 2. View Health Vitals and Rule-Based Alerts
  Future<List<dynamic>> getHealthRecords(String token, String patientId) async {
    final response = await _client.get(
      Uri.parse('$_baseUrl/family/health/$patientId'),
      headers: _headers(token),
    );
    final data = _parseResponse(response);
    return data['records'] as List<dynamic>? ?? [];
  }

  // 3. View Daily Care Reports
  Future<List<dynamic>> getCareReports(String token, String patientId) async {
    final response = await _client.get(
      Uri.parse('$_baseUrl/family/reports/$patientId'),
      headers: _headers(token),
    );
    final data = _parseResponse(response);
    return data['reports'] as List<dynamic>? ?? [];
  }

  // 4. View Elderly Mood Log
  Future<List<dynamic>> getElderlyMoods(String token, String patientId) async {
    final response = await _client.get(
      Uri.parse('$_baseUrl/family/moods/$patientId'),
      headers: _headers(token),
    );
    final data = _parseResponse(response);
    return data['moods'] as List<dynamic>? ?? [];
  }

  // 5. Send Message to Caregiver
  Future<Map<String, dynamic>> sendMessage({
    required String token,
    required String receiverId,
    required String messageText,
  }) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/family/chat'),
      headers: _headers(token),
      body: jsonEncode({
        'receiverId': receiverId,
        'messageText': messageText,
      }),
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