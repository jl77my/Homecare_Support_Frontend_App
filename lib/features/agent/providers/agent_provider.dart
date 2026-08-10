import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/agent_models.dart';
import '../services/agent_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../../caregiver/providers/caregiver_provider.dart';
import '../../elderly/providers/elderly_provider.dart';
import '../../family/providers/family_provider.dart';

class AgentChatState {
  final Map<String, List<AgentChatMessage>> conversations;
  final Map<String, AgentPendingAction> pendingActions;
  final bool isLoading;
  final String? errorMessage;

  const AgentChatState({
    this.conversations = const {},
    this.pendingActions = const {},
    this.isLoading = false,
    this.errorMessage,
  });

  List<AgentChatMessage> messagesFor(String elderlyId) =>
      conversations[elderlyId] ?? const [];

  AgentPendingAction? pendingActionFor(String elderlyId) =>
      pendingActions[elderlyId];

  AgentChatState copyWith({
    Map<String, List<AgentChatMessage>>? conversations,
    Map<String, AgentPendingAction>? pendingActions,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AgentChatState(
      conversations: conversations ?? this.conversations,
      pendingActions: pendingActions ?? this.pendingActions,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

final agentServiceProvider = Provider<AgentService>((ref) => AgentService());

class AgentChatNotifier extends StateNotifier<AgentChatState> {
  AgentChatNotifier(this._service, this._ref) : super(const AgentChatState());

  final AgentService _service;
  final Ref _ref;

  String? get _token => _ref.read(authProvider).token;

  AgentChatMessage _message(AgentMessageRole role, String text, {List<AgentSource> sources = const []}) {
    final now = DateTime.now();
    return AgentChatMessage(
      id: '${now.microsecondsSinceEpoch}-${role.name}',
      role: role,
      text: text,
      timestamp: now,
      sources: sources,
    );
  }

  void _setMessages(String elderlyId, List<AgentChatMessage> messages) {
    final conversations = Map<String, List<AgentChatMessage>>.from(state.conversations);
    conversations[elderlyId] = List.unmodifiable(messages);
    state = state.copyWith(conversations: conversations);
  }

  Future<bool> sendMessage({required String elderlyId, required String text}) async {
    final token = _token;
    final normalized = text.trim();
    if (token == null || elderlyId.isEmpty || normalized.isEmpty || state.isLoading) return false;

    final previousMessages = state.messagesFor(elderlyId);
    _setMessages(elderlyId, [...previousMessages, _message(AgentMessageRole.user, normalized)]);
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final response = await _service.sendMessage(
        token: token,
        elderlyId: elderlyId,
        message: normalized,
        history: previousMessages
            .where((message) => message.text.isNotEmpty)
            .map((message) => message.toHistoryJson())
            .toList(),
      );
      final updatedMessages = [
        ...state.messagesFor(elderlyId),
        _message(AgentMessageRole.assistant, response.reply, sources: response.sources),
      ];
      final pending = Map<String, AgentPendingAction>.from(state.pendingActions);
      if (response.action != null) {
        pending[elderlyId] = response.action!;
      } else {
        pending.remove(elderlyId);
      }
      final conversations = Map<String, List<AgentChatMessage>>.from(state.conversations);
      conversations[elderlyId] = List.unmodifiable(updatedMessages);
      state = state.copyWith(
        conversations: conversations,
        pendingActions: pending,
        isLoading: false,
      );
      return true;
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: error.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }

  Future<bool> confirmAction(String elderlyId) async {
    final token = _token;
    final pendingAction = state.pendingActionFor(elderlyId);
    if (token == null || pendingAction == null || state.isLoading) return false;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result = await _service.confirmAction(
        token: token,
        actionToken: pendingAction.token,
      );
      final pending = Map<String, AgentPendingAction>.from(state.pendingActions)..remove(elderlyId);
      final conversations = Map<String, List<AgentChatMessage>>.from(state.conversations);
      conversations[elderlyId] = List.unmodifiable([
        ...state.messagesFor(elderlyId),
        _message(AgentMessageRole.assistant, 'Done — ${result.message}'),
      ]);
      state = state.copyWith(
        conversations: conversations,
        pendingActions: pending,
        isLoading: false,
      );
      await _refreshExistingScreens(elderlyId, result.resourceType);
      return true;
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: error.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }

  Future<void> _refreshExistingScreens(String elderlyId, String resourceType) async {
    final role = _ref.read(authProvider).user?.role.toLowerCase();
    if (resourceType == 'task') {
      if (role == 'family') {
        await _ref.read(familyDashboardProvider.notifier).fetchCareTasks(elderlyId);
      } else {
        await _ref.read(caregiverProvider.notifier).fetchCareTasks(elderlyId);
      }
    } else if (resourceType == 'reminder' || resourceType == 'medication') {
      await _ref.read(elderlyProvider.notifier).fetchReminders(elderlyId: elderlyId);
    } else if (resourceType == 'careReport') {
      if (role == 'family') {
        await _ref.read(familyDashboardProvider.notifier).fetchDashboardData(elderlyId);
      } else {
        await _ref.read(caregiverProvider.notifier).fetchCareReports(elderlyId);
      }
    }
  }

  void cancelAction(String elderlyId) {
    final pending = Map<String, AgentPendingAction>.from(state.pendingActions)..remove(elderlyId);
    final conversations = Map<String, List<AgentChatMessage>>.from(state.conversations);
    conversations[elderlyId] = List.unmodifiable([
      ...state.messagesFor(elderlyId),
      _message(AgentMessageRole.assistant, 'Action cancelled. No record was changed.'),
    ]);
    state = state.copyWith(conversations: conversations, pendingActions: pending);
  }

  void clearConversation(String elderlyId) {
    final conversations = Map<String, List<AgentChatMessage>>.from(state.conversations)..remove(elderlyId);
    final pending = Map<String, AgentPendingAction>.from(state.pendingActions)..remove(elderlyId);
    state = state.copyWith(conversations: conversations, pendingActions: pending, clearError: true);
  }

  void resetAll() {
    state = const AgentChatState();
  }
}

final agentChatProvider = StateNotifierProvider<AgentChatNotifier, AgentChatState>((ref) {
  final notifier = AgentChatNotifier(ref.watch(agentServiceProvider), ref);
  ref.listen<String?>(
    authProvider.select((state) => state.user?.id),
    (previous, next) {
      if (previous != null && previous != next) notifier.resetAll();
    },
  );
  return notifier;
});
