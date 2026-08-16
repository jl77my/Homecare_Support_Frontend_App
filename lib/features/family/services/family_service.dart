// lib/features/family/services/family_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/models/models.dart';

class FamilyService {
  FamilyService({http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(),
        _baseUrl = baseUrl ?? const String.fromEnvironment('API_BASE_URL', defaultValue: 'http://localhost:3000/api');

  final http.Client _client;
  final String _baseUrl;

  Map<String, String> _headers(String token) => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  Future<Map<String, dynamic>> linkFamilyByCode({
    required String token,
    required String code,
    required String relationship,
  }) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/family/consume-code'),
      headers: _headers(token),
      body: jsonEncode({'code': code, 'relationship': relationship}),
    );
    return _parseResponse(response);
  }

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
        'profilePhotoUrl': (map['profilePhotoUrl'] ?? map['ProfilePhotoUrl'] ?? '').toString(),
        'connectionId': (map['connectionId'] ?? map['ConnectionId'] ?? '').toString(),
        'latestMessageTime': (map['latestMessageTime'] ?? map['LatestMessageTime'] ?? '').toString(),
      };
    }).toList();
  }

  Future<List<dynamic>> getCareTasks(String token, String patientId) async {
    final response = await _client.get(
      Uri.parse('$_baseUrl/family/tasks/$patientId'),
      headers: _headers(token),
    );
    final data = _parseResponse(response);
    return data['tasks'] as List<dynamic>? ?? [];
  }

  Future<Map<String, dynamic>> createTask({
    required String token,
    required String elderlyId,
    required String title,
    required String description,
    required String dueDate,
  }) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/family/tasks/$elderlyId'),
      headers: _headers(token),
      body: jsonEncode({
        'title': title,
        'description': description,
        'dueDate': dueDate,
      }),
    );
    return _parseResponse(response);
  }

  Future<Map<String, dynamic>> editTask({
    required String token,
    required String taskId,
    required String title,
    required String description,
    required String dueDate,
  }) async {
    final response = await _client.put(
      Uri.parse('$_baseUrl/family/tasks/$taskId'),
      headers: _headers(token),
      body: jsonEncode({
        'title': title,
        'description': description,
        'dueDate': dueDate,
      }),
    );
    return _parseResponse(response);
  }

  Future<Map<String, dynamic>> updateTaskStatus({
    required String token,
    required String taskId,
    required String status,
  }) async {
    final response = await _client.put(
      Uri.parse('$_baseUrl/family/tasks/$taskId/status'),
      headers: _headers(token),
      body: jsonEncode({'status': status}),
    );
    return _parseResponse(response);
  }

  Future<List<dynamic>> getHealthRecords(String token, String patientId) async {
    final response = await _client.get(
      Uri.parse('$_baseUrl/family/health/$patientId'),
      headers: _headers(token),
    );
    final data = _parseResponse(response);
    return data['records'] as List<dynamic>? ?? [];
  }

  Future<HealthPrediction> getHealthPrediction(String token, String patientId) async {
    final response = await _client.get(
      Uri.parse('$_baseUrl/family/health/$patientId/prediction'),
      headers: _headers(token),
    );
    final data = _parseResponse(response);
    return HealthPrediction.fromJson(data['prediction'] as Map<String, dynamic>);
  }

  Future<List<dynamic>> getCareReports(String token, String patientId) async {
    final response = await _client.get(
      Uri.parse('$_baseUrl/family/reports/$patientId'),
      headers: _headers(token),
    );
    final data = _parseResponse(response);
    return data['reports'] as List<dynamic>? ?? [];
  }

  Future<Map<String, dynamic>> acknowledgeReport({
    required String token,
    required String reportId,
    required String comment,
  }) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/family/reports/$reportId/acknowledge'),
      headers: _headers(token),
      body: jsonEncode({'comment': comment}),
    );
    return _parseResponse(response);
  }

  Future<String?> getElderlyMoods(String token, String elderlyId) async {
    final endpoint = _baseUrl.contains('family') ? 'family' : 'caregiver';
    final response = await _client.get(
      Uri.parse('$_baseUrl/$endpoint/moods/$elderlyId'),
      headers: _headers(token),
    );
    final data = _parseResponse(response);
    return data['todayMood'] as String?;
  }

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

  Future<Map<String, int>> getUnreadCounts(String token) async {
    final response = await _client.get(
      Uri.parse('$_baseUrl/chat/unread-counts'),
      headers: _headers(token),
    );
    final data = _parseResponse(response);
    final rawCounts = data['unreadCounts'] as Map<String, dynamic>? ?? {};
    return rawCounts.map(
      (elderlyId, count) => MapEntry(elderlyId, (count as num).toInt()),
    );
  }

  Future<int> markChatAsRead({
    required String token,
    required String elderlyId,
    required String lastReadMessageId,
  }) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/chat/messages/$elderlyId/read'),
      headers: _headers(token),
      body: jsonEncode({'lastReadMessageId': lastReadMessageId}),
    );
    final data = _parseResponse(response);
    return (data['unreadCount'] as num?)?.toInt() ?? 0;
  }

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

  Future<Map<String, dynamic>> getCareConnections(String token, String elderlyId) async {
    final endpoint = elderlyId.isNotEmpty ? '$_baseUrl/users/care-connections?elderlyId=$elderlyId' : '$_baseUrl/users/care-connections';
    final response = await _client.get(
      Uri.parse(endpoint),
      headers: _headers(token),
    );
    return _parseResponse(response);
  }

  Future<void> deleteCareConnection(String token, String connectionId) async {
    final response = await _client.delete(
      Uri.parse('$_baseUrl/users/care-connections/$connectionId'),
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
