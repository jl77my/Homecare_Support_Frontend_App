// lib/features/caregiver/services/caregiver_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/models/models.dart';

class CaregiverService {
  CaregiverService({http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(),
        _baseUrl = baseUrl ?? const String.fromEnvironment('API_BASE_URL', defaultValue: 'http://localhost:3000/api');

  final http.Client _client;
  final String _baseUrl;

  Map<String, String> _headers(String token) => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  Future<Map<String, dynamic>> pairWithElderly({
    required String token,
    required String code,
  }) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/pairing/consume'),
      headers: _headers(token),
      body: jsonEncode({'code': code}),
    );
    return _parseResponse(response);
  }

  Future<List<Map<String, String>>> getAssignedSeniors(String token) async {
    final response = await _client.get(
      Uri.parse('$_baseUrl/caregiver/assigned-patients'),
      headers: _headers(token),
    );
    final data = _parseResponse(response);
    final rawList = data['patients'] as List<dynamic>? ?? [];
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

  Future<Map<String, dynamic>> createTask({
    required String token,
    required String title,
    required String description,
    required String dueDate,
    required String assignedTo,
  }) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/caregiver/tasks/$assignedTo'),
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
      Uri.parse('$_baseUrl/caregiver/tasks/$taskId/status'),
      headers: _headers(token),
      body: jsonEncode({'status': status}),
    );
    return _parseResponse(response);
  }

  Future<List<dynamic>> getCareTasks({
    required String token,
    required String patientId,
  }) async {
    final response = await _client.get(
      Uri.parse('$_baseUrl/caregiver/tasks/$patientId'),
      headers: _headers(token),
    );
    final data = _parseResponse(response);
    return data['tasks'] as List<dynamic>? ?? [];
  }

  Future<List<dynamic>> getHealthRecords({
    required String token,
    required String patientId,
  }) async {
    final response = await _client.get(
      Uri.parse('$_baseUrl/caregiver/health/$patientId'),
      headers: _headers(token),
    );
    final data = _parseResponse(response);
    return data['records'] as List<dynamic>? ?? [];
  }

  Future<HealthPrediction> getHealthPrediction({
    required String token,
    required String patientId,
  }) async {
    final response = await _client.get(
      Uri.parse('$_baseUrl/caregiver/health/$patientId/prediction'),
      headers: _headers(token),
    );
    final data = _parseResponse(response);
    return HealthPrediction.fromJson(data['prediction'] as Map<String, dynamic>);
  }

  Future<List<dynamic>> getCareReports({
    required String token,
    required String patientId,
  }) async {
    final response = await _client.get(
      Uri.parse('$_baseUrl/caregiver/reports/$patientId'),
      headers: _headers(token),
    );
    final data = _parseResponse(response);
    return data['reports'] as List<dynamic>? ?? [];
  }

  Future<Map<String, dynamic>> scheduleMedication({
    required String token,
    required String patientId,
    required String medicationName,
    required String dosage,
    required String scheduledDate,
    required String scheduledTime,
    required String category,
    required String frequency,
    String? notes,
  }) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/caregiver/medications'),
      headers: _headers(token),
      body: jsonEncode({
        'patientId': patientId,
        'medicationName': medicationName,
        'dosage': dosage,
        'scheduledDate': scheduledDate,
        'scheduledTime': scheduledTime,
        'category': category,
        'frequency': frequency,
        'notes': notes,
      }),
    );
    return _parseResponse(response);
  }

  Future<Map<String, dynamic>> recordHealth({
    required String token,
    required String patientId,
    required String heartRate,
    required String bloodPressure,
    required String bloodSugar,
    required String notes,
  }) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/caregiver/health'),
      headers: _headers(token),
      body: jsonEncode({
        'patientId': patientId,
        'heartRate': heartRate,
        'bloodPressure': bloodPressure,
        'bloodSugar': bloodSugar,
        'notes': notes,
      }),
    );
    return _parseResponse(response);
  }

  Future<Map<String, dynamic>> submitCareReport({
    required String token,
    required String patientId,
    required String category,
    required String healthStatusNotes,
    required String dailyActivities,
    required String observations,
    String? photoUrl,
  }) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/caregiver/reports'),
      headers: _headers(token),
      body: jsonEncode({
        'patientId': patientId,
        'category': category,
        'healthStatusNotes': healthStatusNotes,
        'dailyActivities': dailyActivities,
        'observations': observations,
        'photoUrl': photoUrl,
      }),
    );
    return _parseResponse(response);
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

  Future<Map<String, dynamic>> editTask({
    required String token,
    required String taskId,
    required String title,
    required String description,
    required String dueDate,
  }) async {
    final response = await _client.put(
      Uri.parse('$_baseUrl/caregiver/tasks/$taskId'),
      headers: _headers(token),
      body: jsonEncode({'title': title, 'description': description, 'dueDate': dueDate}),
    );
    return _parseResponse(response);
  }

  Future<Map<String, dynamic>> editMedication({
    required String token,
    required String medicationId,
    required String medicationName,
    required String dosage,
    required String scheduledDate,
    required String scheduledTime,
    required String category,
    required String frequency,
    String? notes,
  }) async {
    final response = await _client.put(
      Uri.parse('$_baseUrl/caregiver/medications/$medicationId'),
      headers: _headers(token),
      body: jsonEncode({
        'medicationName': medicationName,
        'dosage': dosage,
        'scheduledDate': scheduledDate,
        'scheduledTime': scheduledTime,
        'category': category,
        'frequency': frequency,
        'notes': notes,
      }),
    );
    return _parseResponse(response);
  }

  Future<Map<String, dynamic>> editCareReport({
    required String token,
    required String reportId,
    required String category,
    required String healthStatusNotes,
    required String dailyActivities,
    required String observations,
    String? photoUrl,
  }) async {
    final response = await _client.put(
      Uri.parse('$_baseUrl/caregiver/reports/$reportId'),
      headers: _headers(token),
      body: jsonEncode({
        'category': category,
        'healthStatusNotes': healthStatusNotes,
        'dailyActivities': dailyActivities,
        'observations': observations,
        'photoUrl': photoUrl,
      }),
    );
    return _parseResponse(response);
  }

  Future<void> deleteCareReport({required String token, required String reportId}) async {
    final response = await _client.delete(
      Uri.parse('$_baseUrl/caregiver/reports/$reportId'),
      headers: _headers(token),
    );
    _parseResponse(response);
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
}
