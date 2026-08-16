// lib/features/elderly/services/elderly_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class ElderlyService {
  ElderlyService({http.Client? client, String? baseUrl})
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

  Future<List<dynamic>> getMedications(String token, {String? elderlyId}) async {
    final url = elderlyId != null && elderlyId.isNotEmpty
        ? '$_baseUrl/elderly/medications?elderlyId=$elderlyId'
        : '$_baseUrl/elderly/medications';
        
    final response = await _client.get(
      Uri.parse(url),
      headers: _headers(token),
    );
    final data = _parseResponse(response);
    return data['medications'] as List<dynamic>? ?? [];
  }

  Future<void> deleteMedication({required String token, required String medicationId}) async {
    final response = await _client.delete(
      Uri.parse('$_baseUrl/elderly/medications/$medicationId'),
      headers: _headers(token),
    );
    _parseResponse(response);
  }

  Future<Map<String, dynamic>> confirmMedication({
    required String token,
    required String medicationId,
    required String status,
    String? elderlyId,
  }) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/elderly/medications/confirm'),
      headers: _headers(token),
      body: jsonEncode({
        'medicationId': medicationId,
        'status': status,
        'elderlyId': elderlyId,
      }),
    );
    return _parseResponse(response);
  }

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

  Future<Map<String, dynamic>> triggerSos({
    required String token,
    double? latitude,
    double? longitude,
    double? accuracy,
  }) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/elderly/sos'),
      headers: _headers(token),
      body: jsonEncode({
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        if (accuracy != null) 'accuracy': accuracy,
      }),
    );
    return _parseResponse(response);
  }

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

  Future<Map<String, dynamic>> getCareConnections(String token) async {
    // FIX: Changed from /user/ to /users/
    final response = await _client.get(
      Uri.parse('$_baseUrl/users/care-connections'),
      headers: _headers(token),
    );
    return _parseResponse(response);
  }

  Future<void> deleteCareConnection(String token, String connectionId) async {
    // FIX: Changed from /user/ to /users/
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
    throw Exception(decoded['message'] ?? decoded['error'] ?? 'Request failed');
  }
}
