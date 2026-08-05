import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/models.dart';
import '../../auth/providers/auth_provider.dart';
import '../services/elderly_service.dart';

class ElderlyState {
  final List<Reminder> reminders;
  final bool isSosActive;
  final bool isAudioEnabled;
  final bool isLoading;
  final String? errorMessage;

  const ElderlyState({
    this.reminders = const [],
    this.isSosActive = false,
    this.isAudioEnabled = true,
    this.isLoading = false,
    this.errorMessage,
  });

  ElderlyState copyWith({
    List<Reminder>? reminders,
    bool? isSosActive,
    bool? isAudioEnabled,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ElderlyState(
      reminders: reminders ?? this.reminders,
      isSosActive: isSosActive ?? this.isSosActive,
      isAudioEnabled: isAudioEnabled ?? this.isAudioEnabled,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

final elderlyServiceProvider = Provider<ElderlyService>((ref) => ElderlyService());

class ElderlyNotifier extends StateNotifier<ElderlyState> {
  ElderlyNotifier(this._service, this._ref) : super(const ElderlyState());

  final ElderlyService _service;
  final Ref _ref;

  void toggleAudio() {
    state = state.copyWith(isAudioEnabled: !state.isAudioEnabled);
  }

  Future<void> fetchReminders() async {
    final token = _ref.read(authProvider).token;
    if (token == null) return;

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final rawList = await _service.getMedications(token);
      final reminders = rawList.map((json) => Reminder.fromJson(json)).toList();
      state = state.copyWith(reminders: reminders, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<bool> confirmMedication(String medicationId) async {
    final token = _ref.read(authProvider).token;
    if (token == null) return false;

    try {
      await _service.confirmMedication(
        token: token,
        medicationId: medicationId,
        status: 'Taken',
      );
      await fetchReminders();
      return true;
    } catch (e) {
      state = state.copyWith(
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }

  Future<bool> logMood(String mood) async {
    final token = _ref.read(authProvider).token;
    if (token == null) return false;

    try {
      await _service.logMood(token: token, mood: mood);
      return true;
    } catch (e) {
      state = state.copyWith(
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }

  Future<void> triggerSOS() async {
    final token = _ref.read(authProvider).token;
    if (token == null) return;

    state = state.copyWith(isSosActive: true);
    try {
      await _service.triggerSos(token: token);
    } catch (e) {
      state = state.copyWith(
        isSosActive: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  void resolveSOS() {
    state = state.copyWith(isSosActive: false);
  }
}

final elderlyProvider = StateNotifierProvider<ElderlyNotifier, ElderlyState>((ref) {
  return ElderlyNotifier(ref.watch(elderlyServiceProvider), ref);
});