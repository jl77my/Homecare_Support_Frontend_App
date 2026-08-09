// lib/features/auth/providers/auth_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  AuthNotifier(this._authService) : super(const AuthState());
  final AuthService _authService;

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user = await _authService.login(email: email, password: password);
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
      
      // Update local state directly so UI refreshes immediately
      final updatedUser = state.user!.copyWith(
        name: name,
        phoneNumber: phoneNumber,
        gender: gender,
        profilePhotoUrl: profilePhotoUrl,
      );
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

  void logout() {
    state = const AuthState();
  }

  void clearError() {
    state = state.copyWith(clearError: true, isLoading: false);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(authServiceProvider));
});