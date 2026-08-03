import 'dart:convert';
import 'package:http/http.dart' as http;

class CaregiverService {
  CaregiverService({http.Client? client, String? baseUrl})
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

  // 1. Function 1: Assign Care Task (cite: 1, 2)
  Future<Map<String, dynamic>> createTask({
    required String token,
    required String title,
    required String description,
    required String dueDate,
    required String assignedTo,
  }) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/caregiver/tasks'),
      headers: _headers(token),
      body: jsonEncode({
        'title': title,
        'description': description,
        'dueDate': dueDate,
        'assignedTo': assignedTo,
      }),
    );
    return _parseResponse(response);
  }

  // 2. Function 2: Schedule Medication (cite: 1, 2)
  Future<Map<String, dynamic>> scheduleMedication({
    required String token,
    required String patientId,
    required String medicationName,
    required String dosage,
    required String scheduledTime,
  }) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/caregiver/medications'),
      headers: _headers(token),
      body: jsonEncode({
        'patientId': patientId,
        'medicationName': medicationName,
        'dosage': dosage,
        'scheduledTime': scheduledTime,
      }),
    );
    return _parseResponse(response);
  }

  // 3. Function 3: Record Health Data & Receive Alerts (cite: 1, 2)
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

  // 4. Function 4: Submit Care Report (cite: 1, 2)
  Future<Map<String, dynamic>> submitCareReport({
    required String token,
    required String patientId,
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
        'healthStatusNotes': healthStatusNotes,
        'dailyActivities': dailyActivities,
        'observations': observations,
        'photoUrl': photoUrl,
      }),
    );
    return _parseResponse(response);
  }

  // 5. Function 5: Send In-App Message (cite: 1, 2)
  Future<Map<String, dynamic>> sendMessage({
    required String token,
    required String receiverId,
    required String messageText,
  }) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/caregiver/chat'),
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
    final message = decoded['message'] ?? decoded['error'] ?? 'Request failed';
    throw Exception(message);
  }
}