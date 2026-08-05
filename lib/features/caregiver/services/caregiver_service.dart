import 'dart:convert';
import 'package:http/http.dart' as http;

class CaregiverService {
  CaregiverService({http.Client? client, String? baseUrl})
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

  // 1. Redeem Senior Pairing Code (PairingView)
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

  // 2. Fetch Assigned Seniors for PatientSelectorBar
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
      };
    }).toList();
  }

  // 3. Assign Care Task
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

  // 4. Schedule Medication
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

  // 5. Record Health Data
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

  // 6. Submit Care Report
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

  // 7. Send In-App Message
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