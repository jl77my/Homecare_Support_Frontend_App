import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/agent_models.dart';

class AgentService {
  AgentService({http.Client? client, String? baseUrl})
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

  Future<AgentChatResponse> sendMessage({
    required String token,
    required String elderlyId,
    required String message,
    required List<Map<String, String>> history,
  }) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/agent/chat'),
      headers: _headers(token),
      body: jsonEncode({
        'elderlyId': elderlyId,
        'message': message,
        'history': history,
      }),
    );
    return AgentChatResponse.fromJson(_parseResponse(response));
  }

  Future<AgentActionResult> confirmAction({
    required String token,
    required String actionToken,
  }) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/agent/actions/confirm'),
      headers: _headers(token),
      body: jsonEncode({'actionToken': actionToken}),
    );
    return AgentActionResult.fromJson(_parseResponse(response));
  }

  Map<String, dynamic> _parseResponse(http.Response response) {
    Map<String, dynamic> decoded = const {};
    try {
      final value = jsonDecode(response.body);
      if (value is Map<String, dynamic>) decoded = value;
    } catch (_) {
      if (response.statusCode >= 200 && response.statusCode < 300) {
        throw Exception('The backend returned an unreadable response.');
      }
    }
    if (response.statusCode >= 200 && response.statusCode < 300) return decoded;
    throw Exception(
      decoded['error']?.toString() ??
          decoded['message']?.toString() ??
          'Agent request failed (${response.statusCode}).',
    );
  }
}
