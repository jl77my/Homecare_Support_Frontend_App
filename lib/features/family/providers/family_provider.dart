// lib/features/family/providers/family_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/models.dart';
import '../../auth/providers/auth_provider.dart';
import '../services/family_service.dart';

class FamilyDashboardState {
  final HealthVitals? latestVital;
  final CareReport? latestReport;
  final ChatMessage? latestMessage;
  final int totalReportsCount;
  final bool isLoading;
  final String? errorMessage;

  const FamilyDashboardState({
    this.latestVital,
    this.latestReport,
    this.latestMessage,
    this.totalReportsCount = 0,
    this.isLoading = false,
    this.errorMessage,
  });

  FamilyDashboardState copyWith({
    HealthVitals? latestVital,
    CareReport? latestReport,
    ChatMessage? latestMessage,
    int? totalReportsCount,
    bool? isLoading,
    String? errorMessage,
  }) {
    return FamilyDashboardState(
      latestVital: latestVital ?? this.latestVital,
      latestReport: latestReport ?? this.latestReport,
      latestMessage: latestMessage ?? this.latestMessage,
      totalReportsCount: totalReportsCount ?? this.totalReportsCount,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

final familyServiceProvider = Provider<FamilyService>((ref) => FamilyService());

class FamilyDashboardNotifier extends StateNotifier<FamilyDashboardState> {
  FamilyDashboardNotifier(this._service, this._ref) : super(const FamilyDashboardState());

  final FamilyService _service;
  final Ref _ref;

  Future<void> fetchDashboardData(String patientId) async {
    final token = _ref.read(authProvider).token;
    if (token == null) return;

    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final reports = await _service.getCareReports(token, patientId);
      final healthRecords = await _service.getHealthRecords(token, patientId);
      final moods = await _service.getElderlyMoods(token, patientId);

      final latestReport = reports.isNotEmpty
          ? CareReport.fromJson(reports.first as Map<String, dynamic>)
          : null;
      final latestVital = healthRecords.isNotEmpty
          ? HealthVitals.fromJson(healthRecords.first as Map<String, dynamic>)
          : null;
      final latestMessage = moods.isNotEmpty
          ? ChatMessage.fromJson(moods.first as Map<String, dynamic>)
          : null;

      state = state.copyWith(
        latestVital: latestVital,
        latestReport: latestReport,
        latestMessage: latestMessage,
        totalReportsCount: reports.length,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }
}

final familyDashboardProvider = StateNotifierProvider<FamilyDashboardNotifier, FamilyDashboardState>((ref) {
  return FamilyDashboardNotifier(ref.watch(familyServiceProvider), ref);
});