// lib/features/auth/providers/auth_provider.dart
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthState {
  final UserModel? user;
  final String? token;
  final bool isLoading;
  final String? errorMessage;
  
  const AuthState({
    this.user,
    this.token,
    this.isLoading = false,
    this.errorMessage,
  });

  AuthState copyWith({
    UserModel? user,
    String? token,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AuthState(
      user: user ?? this.user,
      token: token ?? this.token,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

class AuthNotifier extends StateNotifier<AuthState> {
  // 5. Persistent Session Boot
  AuthNotifier(this._authService) : super(const AuthState(isLoading: true)) {
    _loadStoredSession();
  }

  final AuthService _authService;

  Future<void> _loadStoredSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString('current_user');
      final token = prefs.getString('auth_token');

      if (userJson != null && token != null) {
        final Map<String, dynamic> decodedUser = jsonDecode(userJson);
        state = AuthState(
          user: UserModel.fromJson(decodedUser),
          token: token,
          isLoading: false,
        );
      } else {
        state = const AuthState(isLoading: false);
      }
    } catch (e) {
      state = const AuthState(isLoading: false);
    }
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user = await _authService.login(email: email, password: password);
      
      // 5. Save session to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', user.token ?? user.id);
      await prefs.setString('current_user', jsonEncode(user.toJson()));

      state = AuthState(
        user: user,
        token: user.token ?? user.id,
        isLoading: false,
      );
      return true;
    } catch (error) {
      state = AuthState(
        isLoading: false,
        errorMessage: error.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _authService.register(
        name: name,
        email: email,
        password: password,
        role: role,
      );
      state = const AuthState();
      return true;
    } catch (error) {
      state = AuthState(
        isLoading: false,
        errorMessage: error.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }

  Future<bool> updateProfile({
    required String name,
    required String phoneNumber,
    required String gender,
    String? profilePhotoUrl,
  }) async {
    if (state.token == null || state.user == null) return false;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _authService.updateProfile(
        token: state.token!,
        name: name,
        phoneNumber: phoneNumber,
        gender: gender,
        profilePhotoUrl: profilePhotoUrl,
      );
      
      final updatedUser = state.user!.copyWith(
        name: name,
        phoneNumber: phoneNumber,
        gender: gender,
        profilePhotoUrl: profilePhotoUrl,
      );

      // Update persisted session
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('current_user', jsonEncode(updatedUser.toJson()));

      state = state.copyWith(user: updatedUser, isLoading: false);
      return true;
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: error.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (state.token == null) return false;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _authService.changePassword(
        token: state.token!,
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      state = state.copyWith(isLoading: false);
      return true;
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: error.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Clears persistent session
    state = const AuthState();
  }

  void clearError() {
    state = state.copyWith(clearError: true, isLoading: false);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(authServiceProvider));
});