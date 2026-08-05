import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/models.dart';
import '../../auth/providers/auth_provider.dart';
import '../services/caregiver_service.dart';

// 1. Immutable Caregiver State
class CaregiverState {
  final List<CareTask> tasks;
  final List<HealthVitals> vitals;
  final List<CareReport> reports;
  final bool isLoading;
  final String? errorMessage;

  const CaregiverState({
    this.tasks = const [],
    this.vitals = const [],
    this.reports = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  CaregiverState copyWith({
    List<CareTask>? tasks,
    List<HealthVitals>? vitals,
    List<CareReport>? reports,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return CaregiverState(
      tasks: tasks ?? this.tasks,
      vitals: vitals ?? this.vitals,
      reports: reports ?? this.reports,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

// 2. Service Provider
final caregiverServiceProvider = Provider<CaregiverService>((ref) => CaregiverService());

// 3. StateNotifier Logic Class
class CaregiverNotifier extends StateNotifier<CaregiverState> {
  CaregiverNotifier(this._service, this._ref) : super(const CaregiverState());

  final CaregiverService _service;
  final Ref _ref;

  // Helper method to retrieve the JWT token safely
  String? get _token => _ref.read(authProvider).token;

  // Function 1: Assign Care Task
  Future<bool> createTask({
    required String title,
    required String description,
    required String dueDate,
    required String assignedTo,
  }) async {
    final token = _token;
    if (token == null) return _handleAuthError();

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _service.createTask(
        token: token,
        title: title,
        description: description,
        dueDate: dueDate,
        assignedTo: assignedTo,
      );
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      return _handleException(e);
    }
  }

  // Function 2: Schedule Medication
  Future<bool> scheduleMedication({
    required String patientId,
    required String medicationName,
    required String dosage,
    required String scheduledTime,
  }) async {
    final token = _token;
    if (token == null) return _handleAuthError();

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _service.scheduleMedication(
        token: token,
        patientId: patientId,
        medicationName: medicationName,
        dosage: dosage,
        scheduledTime: scheduledTime,
      );
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      return _handleException(e);
    }
  }

  // Function 3: Record Health Data & Receive Rule Alerts
  Future<bool> recordHealth({
    required String patientId,
    required String heartRate,
    required String bloodPressure,
    required String bloodSugar,
    required String notes,
  }) async {
    final token = _token;
    if (token == null) return _handleAuthError();

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _service.recordHealth(
        token: token,
        patientId: patientId,
        heartRate: heartRate,
        bloodPressure: bloodPressure,
        bloodSugar: bloodSugar,
        notes: notes,
      );
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      return _handleException(e);
    }
  }

  // Function 4: Submit Care Report
  Future<bool> submitCareReport({
    required String patientId,
    required String healthStatusNotes,
    required String dailyActivities,
    required String observations,
    String? photoUrl,
  }) async {
    final token = _token;
    if (token == null) return _handleAuthError();

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _service.submitCareReport(
        token: token,
        patientId: patientId,
        healthStatusNotes: healthStatusNotes,
        dailyActivities: dailyActivities,
        observations: observations,
        photoUrl: photoUrl,
      );
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      return _handleException(e);
    }
  }

  // Function 5: Send In-App Message
  Future<bool> sendMessage({
    required String receiverId,
    required String messageText,
  }) async {
    final token = _token;
    if (token == null) return _handleAuthError();

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _service.sendMessage(
        token: token,
        receiverId: receiverId,
        messageText: messageText,
      );
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      return _handleException(e);
    }
  }

  bool _handleAuthError() {
    state = state.copyWith(
      isLoading: false,
      errorMessage: 'Session expired or invalid token. Please log in again.',
    );
    return false;
  }

  bool _handleException(dynamic e) {
    state = state.copyWith(
      isLoading: false,
      errorMessage: e.toString().replaceFirst('Exception: ', ''),
    );
    return false;
  }
}

// 4. Global Caregiver Riverpod Provider
final caregiverProvider = StateNotifierProvider<CaregiverNotifier, CaregiverState>((ref) {
  return CaregiverNotifier(ref.watch(caregiverServiceProvider), ref);
});