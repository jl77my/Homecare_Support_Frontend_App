import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/user_model.dart';

class AuthService {
  AuthService({http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(),
        _baseUrl = baseUrl ??
            const String.fromEnvironment(
              'API_BASE_URL',
              defaultValue: 'http://localhost:3000/api',
            );

  final http.Client _client;
  final String _baseUrl;

  Future<UserModel> login({required String email, required String password}) {
    return _sendAuthRequest(
      endpoint: '/users/login',
      payload: {'Email': email, 'Password': password},
    );
  }

  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
    required String role,
  }) {
    return _sendAuthRequest(
      endpoint: '/users/register',
      payload: {
        'Name': name,
        'Email': email,
        'Password': password,
        'Role': role,
      },
    );
  }

  Future<UserModel> _sendAuthRequest({
    required String endpoint,
    required Map<String, dynamic> payload,
  }) async {
    late final http.Response response;

    try {
      response = await _client.post(
        Uri.parse('$_baseUrl$endpoint'),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );
    } on http.ClientException catch (error) {
      throw Exception(
        'Network request failed. If you are running Flutter web, the backend at '
        '$_baseUrl must allow CORS for the app origin and respond to OPTIONS '
        'preflight requests. Original error: ${error.message}',
      );
    } catch (error) {
      throw Exception('Network request failed: $error');
    }

    final decodedBody = _decodeResponse(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final userJson = decodedBody['user'] is Map<String, dynamic>
          ? decodedBody['user'] as Map<String, dynamic>
          : decodedBody;
      return UserModel.fromJson({...userJson, 'token': decodedBody['token']});
    }

    final message = decodedBody['message']?.toString() ??
        decodedBody['error']?.toString() ??
        'Authentication failed';
    throw Exception(message);
  }

  Map<String, dynamic> _decodeResponse(String body) {
    if (body.isEmpty) {
      return const <String, dynamic>{};
    }

    final decoded = jsonDecode(body);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }

    return <String, dynamic>{'data': decoded};
  }
}