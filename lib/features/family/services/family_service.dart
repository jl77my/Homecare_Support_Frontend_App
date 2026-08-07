import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/models/models.dart';

class FamilyService {
  FamilyService({http.Client? client, String? baseUrl})
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

  // 1. Consume Family Pairing Code (family_pairing_view.dart)
  Future<Map<String, dynamic>> linkFamilyByCode({
    required String token,
    required String code,
    required String relationship,
  }) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/family/consume-code'),
      headers: _headers(token),
      body: jsonEncode({
        'code': code,
        'relationship': relationship,
      }),
    );
    return _parseResponse(response);
  }

  // 2. Fetch Linked Elderly List for Family Member
  Future<List<Map<String, String>>> getLinkedElderly(String token) async {
    final response = await _client.get(
      Uri.parse('$_baseUrl/family/linked-elderly'),
      headers: _headers(token),
    );
    final data = _parseResponse(response);
    final rawList = data['seniors'] as List<dynamic>? ?? [];
    return rawList.map((item) {
      final map = item as Map<String, dynamic>;
      return {
        'elderlyId': (map['elderlyId'] ?? map['id'] ?? map['Id'] ?? '').toString(),
        'name': (map['name'] ?? map['Name'] ?? 'Senior User').toString(),
      };
    }).toList();
  }

  // 3. Monitor Care Tasks
  Future<List<dynamic>> getCareTasks(String token, String patientId) async {
    final response = await _client.get(
      Uri.parse('$_baseUrl/family/tasks/$patientId'),
      headers: _headers(token),
    );
    final data = _parseResponse(response);
    return data['tasks'] as List<dynamic>? ?? [];
  }

  // 4. View Health Vitals and Rule-Based Alerts
  Future<List<dynamic>> getHealthRecords(String token, String patientId) async {
    final response = await _client.get(
      Uri.parse('$_baseUrl/family/health/$patientId'),
      headers: _headers(token),
    );
    final data = _parseResponse(response);
    return data['records'] as List<dynamic>? ?? [];
  }

  // 5. View Daily Care Reports
  Future<List<dynamic>> getCareReports(String token, String patientId) async {
    final response = await _client.get(
      Uri.parse('$_baseUrl/family/reports/$patientId'),
      headers: _headers(token),
    );
    final data = _parseResponse(response);
    return data['reports'] as List<dynamic>? ?? [];
  }

  // 6. View Elderly Mood Log
  Future<List<dynamic>> getElderlyMoods(String token, String patientId) async {
    final response = await _client.get(
      Uri.parse('$_baseUrl/family/moods/$patientId'),
      headers: _headers(token),
    );
    final data = _parseResponse(response);
    return data['moods'] as List<dynamic>? ?? [];
  }

  // 7. Fetch Isolated Chat Messages for Family Channel
  Future<List<ChatMessage>> getChatMessages({
    required String token,
    required String elderlyId,
  }) async {
    final response = await _client.get(
      Uri.parse('$_baseUrl/chat/messages/$elderlyId'),
      headers: _headers(token),
    );
    final data = _parseResponse(response);
    final rawList = data['messages'] as List<dynamic>? ?? [];
    return rawList.map((json) => ChatMessage.fromJson(json)).toList();
  }

  // 8. Send Message to Isolated Senior Channel
  Future<Map<String, dynamic>> sendMessage({
    required String token,
    required String elderlyId,
    required String messageText,
    String? receiverId,
  }) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/chat/send'),
      headers: _headers(token),
      body: jsonEncode({
        'elderlyId': elderlyId,
        'messageText': messageText,
        if (receiverId != null) 'receiverId': receiverId,
      }),
    );
    return _parseResponse(response);
  }

  // 9. Fetch Care Connections for Active Elderly Context
  Future<Map<String, dynamic>> getCareConnections(String token, String elderlyId) async {
    final response = await _client.get(
      Uri.parse('$_baseUrl/user/care-connections?elderlyId=$elderlyId'),
      headers: _headers(token),
    );
    return _parseResponse(response);
  }

  // 10. Delete / Unlink Care Connection (Enforcing Family Role Privileges)
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
    final message = decoded['message'] ?? decoded['error'] ?? 'Request failed';
    throw Exception(message);
  }
}