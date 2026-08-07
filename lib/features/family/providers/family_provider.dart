import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/models.dart';
import '../../auth/providers/auth_provider.dart';
import '../services/family_service.dart';

// 1. Immutable Family Dashboard State
class FamilyDashboardState {
  final HealthVitals? latestVital;
  final CareReport? latestReport;
  final ChatMessage? latestMessage;
  final List<Map<String, String>> linkedSeniors; // Added for linked elderly list
  final List<ChatMessage> currentChatMessages;   // Isolated channel thread messages
  final List<dynamic> activeCaregivers;           // Care connections list
  final List<dynamic> activeFamilyMembers;        // Care connections list
  final String selectedElderlyId;                // Selected active senior context
  final int totalReportsCount;
  final bool isLoading;
  final String? errorMessage;

  const FamilyDashboardState({
    this.latestVital,
    this.latestReport,
    this.latestMessage,
    this.linkedSeniors = const [],
    this.currentChatMessages = const [],
    this.activeCaregivers = const [],
    this.activeFamilyMembers = const [],
    this.selectedElderlyId = '',
    this.totalReportsCount = 0,
    this.isLoading = false,
    this.errorMessage,
  });

  FamilyDashboardState copyWith({
    HealthVitals? latestVital,
    CareReport? latestReport,
    ChatMessage? latestMessage,
    List<Map<String, String>>? linkedSeniors,
    List<ChatMessage>? currentChatMessages,
    List<dynamic>? activeCaregivers,
    List<dynamic>? activeFamilyMembers,
    String? selectedElderlyId,
    int? totalReportsCount,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return FamilyDashboardState(
      latestVital: latestVital ?? this.latestVital,
      latestReport: latestReport ?? this.latestReport,
      latestMessage: latestMessage ?? this.latestMessage,
      linkedSeniors: linkedSeniors ?? this.linkedSeniors,
      currentChatMessages: currentChatMessages ?? this.currentChatMessages,
      activeCaregivers: activeCaregivers ?? this.activeCaregivers,
      activeFamilyMembers: activeFamilyMembers ?? this.activeFamilyMembers,
      selectedElderlyId: selectedElderlyId ?? this.selectedElderlyId,
      totalReportsCount: totalReportsCount ?? this.totalReportsCount,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

// 2. Global Family Service Provider
final familyServiceProvider = Provider<FamilyService>((ref) => FamilyService());

// 3. StateNotifier Logic Class
class FamilyDashboardNotifier extends StateNotifier<FamilyDashboardState> {
  FamilyDashboardNotifier(this._service, this._ref) : super(const FamilyDashboardState());

  final FamilyService _service;
  final Ref _ref;

  String? get _token => _ref.read(authProvider).token;

  // Redeem Family Pairing Code (family_pairing_view.dart)
  Future<bool> linkFamilyByCode({
    required String code,
    required String relationship,
  }) async {
    final token = _token;
    if (token == null) return _handleAuthError();

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _service.linkFamilyByCode(
        token: token,
        code: code,
        relationship: relationship,
      );
      await fetchLinkedSeniors(); // Refresh senior list after pairing
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      return _handleException(e);
    }
  }

  // Fetch List of Linked Seniors
  Future<void> fetchLinkedSeniors() async {
    final token = _token;
    if (token == null) return;

    try {
      final seniors = await _service.getLinkedElderly(token);
      String currentActive = state.selectedElderlyId;
      if (currentActive.isEmpty && seniors.isNotEmpty) {
        currentActive = seniors.first['elderlyId'] ?? '';
      }
      state = state.copyWith(
        linkedSeniors: seniors,
        selectedElderlyId: currentActive,
      );
      if (currentActive.isNotEmpty) {
        await fetchDashboardData(currentActive);
      }
    } catch (e) {
      _handleException(e);
    }
  }

  // Switch Active Senior Context
  Future<void> switchElderlyContext(String elderlyId) async {
    state = state.copyWith(selectedElderlyId: elderlyId);
    await fetchDashboardData(elderlyId);
  }

  // Fetch Care Connections for Selected Senior
  Future<void> fetchCareConnections(String elderlyId) async {
    final token = _token;
    if (token == null) return;

    try {
      final data = await _service.getCareConnections(token, elderlyId);
      state = state.copyWith(
        activeCaregivers: data['caregivers'] as List<dynamic>? ?? [],
        activeFamilyMembers: data['familyMembers'] as List<dynamic>? ?? [],
      );
    } catch (e) {
      _handleException(e);
    }
  }

  // Delete / Remove Care Connection (Enforcing Family Role Privileges)
  Future<bool> deleteCareConnection(String connectionId) async {
    final token = _token;
    if (token == null) return _handleAuthError();

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _service.deleteCareConnection(token, connectionId);
      if (state.selectedElderlyId.isNotEmpty) {
        await fetchCareConnections(state.selectedElderlyId);
      }
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      return _handleException(e);
    }
  }

  // Fetch Dashboard Monitoring Data for Selected Senior
  Future<void> fetchDashboardData(String elderlyId) async {
    final token = _token;
    if (token == null) return;

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final reports = await _service.getCareReports(token, elderlyId);
      final healthRecords = await _service.getHealthRecords(token, elderlyId);
      final chatMsgs = await _service.getChatMessages(token: token, elderlyId: elderlyId);

      final latestReport = reports.isNotEmpty
          ? CareReport.fromJson(reports.first as Map<String, dynamic>)
          : null;
      final latestVital = healthRecords.isNotEmpty
          ? HealthVitals.fromJson(healthRecords.first as Map<String, dynamic>)
          : null;
      final latestMessage = chatMsgs.isNotEmpty ? chatMsgs.last : null;

      state = state.copyWith(
        latestVital: latestVital,
        latestReport: latestReport,
        latestMessage: latestMessage,
        currentChatMessages: chatMsgs,
        totalReportsCount: reports.length,
        isLoading: false,
      );

      await fetchCareConnections(elderlyId);
    } catch (e) {
      _handleException(e);
    }
  }

  // Fetch Isolated Chat Messages Thread
  Future<void> fetchChatMessages(String elderlyId) async {
    final token = _token;
    if (token == null) return;

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final messages = await _service.getChatMessages(
        token: token,
        elderlyId: elderlyId,
      );
      state = state.copyWith(
        currentChatMessages: messages,
        latestMessage: messages.isNotEmpty ? messages.last : state.latestMessage,
        isLoading: false,
      );
    } catch (e) {
      _handleException(e);
    }
  }

  // Send Message to Isolated Family Channel
  Future<bool> sendChatMessage({
    required String elderlyId,
    required String messageText,
    String? receiverId,
  }) async {
    final token = _token;
    if (token == null) return _handleAuthError();

    try {
      await _service.sendMessage(
        token: token,
        elderlyId: elderlyId,
        messageText: messageText,
        receiverId: receiverId,
      );
      await fetchChatMessages(elderlyId); // Refresh thread immediately
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

// 4. Global Family Riverpod Provider
final familyDashboardProvider = StateNotifierProvider<FamilyDashboardNotifier, FamilyDashboardState>((ref) {
  return FamilyDashboardNotifier(ref.watch(familyServiceProvider), ref);
}); 
