// lib/features/family/providers/family_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/models.dart';
import '../../auth/providers/auth_provider.dart';
import '../services/family_service.dart';

class FamilyDashboardState {
  final List<CareTask> tasks;
  final HealthVitals? latestVital;
  final CareReport? latestReport;
  final List<CareReport> reports;
  final ChatMessage? latestMessage;
  final List<Map<String, String>> linkedSeniors;
  final List<ChatMessage> currentChatMessages;
  final List<dynamic> activeCaregivers;
  final List<dynamic> activeFamilyMembers;
  final String selectedElderlyId;
  final int totalReportsCount;
  final bool isLoading;
  final String? errorMessage;
  final String? todayMood;
  final Map<String, String> lastReadMessages; 

  const FamilyDashboardState({
    this.tasks = const [],
    this.latestVital,
    this.latestReport,
    this.reports = const [],
    this.latestMessage,
    this.linkedSeniors = const [],
    this.currentChatMessages = const [],
    this.activeCaregivers = const [],
    this.activeFamilyMembers = const [],
    this.selectedElderlyId = '',
    this.totalReportsCount = 0,
    this.isLoading = false,
    this.errorMessage,
    this.todayMood,
    this.lastReadMessages = const {}, 
  });

  FamilyDashboardState copyWith({
    List<CareTask>? tasks,
    HealthVitals? latestVital,
    CareReport? latestReport,
    List<CareReport>? reports,
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
    String? todayMood,
    Map<String, String>? lastReadMessages,
  }) {
    return FamilyDashboardState(
      tasks: tasks ?? this.tasks,
      latestVital: latestVital ?? this.latestVital,
      latestReport: latestReport ?? this.latestReport,
      reports: reports ?? this.reports,
      latestMessage: latestMessage ?? this.latestMessage,
      linkedSeniors: linkedSeniors ?? this.linkedSeniors,
      currentChatMessages: currentChatMessages ?? this.currentChatMessages,
      activeCaregivers: activeCaregivers ?? this.activeCaregivers,
      activeFamilyMembers: activeFamilyMembers ?? this.activeFamilyMembers,
      selectedElderlyId: selectedElderlyId ?? this.selectedElderlyId,
      totalReportsCount: totalReportsCount ?? this.totalReportsCount,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      todayMood: todayMood ?? this.todayMood,
      lastReadMessages: lastReadMessages ?? this.lastReadMessages, 
    );
  }
}

final familyServiceProvider = Provider<FamilyService>((ref) => FamilyService());

class FamilyDashboardNotifier extends StateNotifier<FamilyDashboardState> {
  FamilyDashboardNotifier(this._service, this._ref) : super(const FamilyDashboardState());
  
  final FamilyService _service;
  final Ref _ref;
  
  String? get _token => _ref.read(authProvider).token;

  void markChatAsRead(String elderlyId) {
    if (state.currentChatMessages.isNotEmpty) {
      final updatedMap = Map<String, String>.from(state.lastReadMessages);
      updatedMap[elderlyId] = state.currentChatMessages.last.id;
      state = state.copyWith(lastReadMessages: updatedMap);
    }
  }

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
      await fetchLinkedSeniors();
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      return _handleException(e);
    }
  }

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

  Future<void> switchElderlyContext(String elderlyId) async {
    state = state.copyWith(selectedElderlyId: elderlyId);
    await fetchDashboardData(elderlyId);
  }

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

  Future<void> fetchCareTasks(String elderlyId) async {
    final token = _token;
    if (token == null) return;
    try {
      final rawTasks = await _service.getCareTasks(token, elderlyId);
      final parsedTasks = rawTasks.map((json) => CareTask.fromJson(json)).toList();
      state = state.copyWith(tasks: parsedTasks);
    } catch (e) {
      _handleException(e);
    }
  }

  Future<bool> createTask({
    required String elderlyId,
    required String title,
    required String description,
    required String dueDate,
  }) async {
    final token = _token;
    if (token == null) return _handleAuthError();
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _service.createTask(
        token: token,
        elderlyId: elderlyId,
        title: title,
        description: description,
        dueDate: dueDate,
      );
      await fetchCareTasks(elderlyId);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      return _handleException(e);
    }
  }

  Future<bool> editTask({
    required String taskId,
    required String elderlyId,
    required String title,
    required String description,
    required String dueDate,
  }) async {
    final token = _token;
    if (token == null) return _handleAuthError();
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _service.editTask(
        token: token,
        taskId: taskId,
        title: title,
        description: description,
        dueDate: dueDate,
      );
      await fetchCareTasks(elderlyId);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      return _handleException(e);
    }
  }

  Future<bool> updateTaskStatus(String taskId, String status) async {
    final token = _token;
    if (token == null) return _handleAuthError();
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _service.updateTaskStatus(
        token: token,
        taskId: taskId,
        status: status,
      );
      if (state.selectedElderlyId.isNotEmpty) {
        await fetchCareTasks(state.selectedElderlyId);
      }
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      return _handleException(e);
    }
  }

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

  Future<void> fetchDashboardData(String elderlyId) async {
    final token = _token;
    if (token == null) return;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final rawReports = await _service.getCareReports(token, elderlyId);
      final parsedReports = rawReports.map((r) => CareReport.fromJson(r)).toList();
      final healthRecords = await _service.getHealthRecords(token, elderlyId);
      final chatMsgs = await _service.getChatMessages(token: token, elderlyId: elderlyId);
      final fetchedMood = await _service.getElderlyMoods(token, elderlyId); 
      
      final latestReport = parsedReports.isNotEmpty ? parsedReports.first : null;
      final latestVital = healthRecords.isNotEmpty
          ? HealthVitals.fromJson(healthRecords.first as Map<String, dynamic>)
          : null;
      final latestMessage = chatMsgs.isNotEmpty ? chatMsgs.last : null;
      
      state = state.copyWith(
        latestVital: latestVital,
        latestReport: latestReport,
        reports: parsedReports,
        latestMessage: latestMessage,
        currentChatMessages: chatMsgs,
        totalReportsCount: parsedReports.length,
        todayMood: fetchedMood, 
        isLoading: false,
      );
      await fetchCareConnections(elderlyId);
      await fetchCareTasks(elderlyId);
    } catch (e) {
      _handleException(e);
    }
  }

  Future<bool> acknowledgeReport(String reportId, String comment) async {
    final token = _token;
    if (token == null) return _handleAuthError();
    try {
      await _service.acknowledgeReport(
        token: token,
        reportId: reportId,
        comment: comment,
      );
      if (state.selectedElderlyId.isNotEmpty) {
        await fetchDashboardData(state.selectedElderlyId);
      }
      return true;
    } catch (e) {
      return _handleException(e);
    }
  }

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
      await fetchChatMessages(elderlyId);
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

final familyDashboardProvider = StateNotifierProvider<FamilyDashboardNotifier, FamilyDashboardState>((ref) {
  return FamilyDashboardNotifier(ref.watch(familyServiceProvider), ref);
});