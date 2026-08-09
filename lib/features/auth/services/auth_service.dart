// lib/features/auth/services/auth_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';

class AuthService {
  AuthService({http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(),
        _baseUrl = baseUrl ??
            const String.fromEnvironment(
              'API_BASE_URL',
              defaultValue: 'http://localhost:3000/api', // 10.0.2.2 for Android Emulator
            );

  final http.Client _client;
  final String _baseUrl;

  Map<String, String> _headers(String? token) => {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

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

  Future<void> updateProfile({
    required String token,
    required String name,
    String? phoneNumber,
    String? gender,
    String? profilePhotoUrl,
  }) async {
    final response = await _client.put(
      Uri.parse('$_baseUrl/users/profile'),
      headers: _headers(token),
      body: jsonEncode({
        'name': name,
        'phoneNumber': phoneNumber,
        'gender': gender,
        'profilePhotoUrl': profilePhotoUrl,
      }),
    );
    _parseBasicResponse(response);
  }

  Future<void> changePassword({
    required String token,
    required String currentPassword,
    required String newPassword,
  }) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/users/change-password'),
      headers: _headers(token),
      body: jsonEncode({
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      }),
    );
    _parseBasicResponse(response);
  }

  Future<UserModel> _sendAuthRequest({
    required String endpoint,
    required Map<String, dynamic> payload,
  }) async {
    late final http.Response response;
    try {
      response = await _client.post(
        Uri.parse('$_baseUrl$endpoint'),
        headers: _headers(null),
        body: jsonEncode(payload),
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

  void _parseBasicResponse(http.Response response) {
    final decoded = jsonDecode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }
    throw Exception(decoded['message'] ?? decoded['error'] ?? 'Request failed');
  }

  Map<String, dynamic> _decodeResponse(String body) {
    if (body.isEmpty) return const <String, dynamic>{};
    final decoded = jsonDecode(body);
    if (decoded is Map<String, dynamic>) return decoded;
    return <String, dynamic>{'data': decoded};
  }
}