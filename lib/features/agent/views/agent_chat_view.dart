import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../../caregiver/providers/caregiver_provider.dart';
import '../../caregiver/views/pairing_view.dart';
import '../../caregiver/widgets/patient_selector_bar.dart';
import '../../family/providers/family_provider.dart';
import '../../family/views/family_pairing_view.dart';
import '../models/agent_models.dart';
import '../providers/agent_provider.dart';

class AgentChatView extends ConsumerStatefulWidget {
  const AgentChatView({super.key});

  @override
  ConsumerState<AgentChatView> createState() => _AgentChatViewState();
}

class _AgentChatViewState extends ConsumerState<AgentChatView> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  int _lastMessageCount = 0;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      final role = ref.read(authProvider).user?.role.toLowerCase();
      if (role == 'family') {
        await ref.read(familyDashboardProvider.notifier).fetchLinkedSeniors();
      } else if (role == 'caregiver') {
        await ref.read(caregiverProvider.notifier).fetchAssignedSeniors();
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send(String elderlyId, {String? suggestion}) async {
    final text = (suggestion ?? _messageController.text).trim();
    if (text.isEmpty || elderlyId.isEmpty) return;
    _messageController.clear();
    await ref.read(agentChatProvider.notifier).sendMessage(
          elderlyId: elderlyId,
          text: text,
        );
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final isFamily = user?.role.toLowerCase() == 'family';
    final familyState = ref.watch(familyDashboardProvider);
    final caregiverState = ref.watch(caregiverProvider);
    final agentState = ref.watch(agentChatProvider);

    final seniors = isFamily ? familyState.linkedSeniors : caregiverState.assignedSeniors;
    final elderlyId = isFamily ? familyState.selectedElderlyId : caregiverState.activeElderlyId;
    final messages = agentState.messagesFor(elderlyId);
    final pendingAction = agentState.pendingActionFor(elderlyId);
    String? selectedName;
    for (final senior in seniors) {
      if (senior['elderlyId'] == elderlyId) {
        selectedName = senior['name'] ?? 'Selected senior';
        break;
      }
    }

    if (messages.length != _lastMessageCount) {
      _lastMessageCount = messages.length;
      _scrollToBottom();
    }

    ref.listen<String?>(
      agentChatProvider.select((state) => state.errorMessage),
      (previous, next) {
        if (next != null && next != previous && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(next), backgroundColor: const Color(0xFFDC2626)),
          );
        }
      },
    );

    return Column(
      children: [
        const SizedBox(height: 8),
        _buildHeader(elderlyId),
        if (seniors.isNotEmpty)
          PatientSelectorBar(
            assignedSeniors: seniors,
            selectedElderlyId: elderlyId,
            onElderlySelected: (newId) {
              if (isFamily) {
                ref.read(familyDashboardProvider.notifier).switchElderlyContext(newId);
              } else {
                ref.read(caregiverProvider.notifier).switchElderlyContext(newId);
              }
            },
            onPairNewElderly: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => isFamily ? const FamilyPairingView() : const PairingView(),
                ),
              );
            },
          ),
        Expanded(
          child: elderlyId.isEmpty
              ? _buildNoPatient()
              : ListView(
                  controller: _scrollController,
                  padding: const EdgeInsets.only(top: 12, bottom: 12),
                  children: [
                    if (messages.isEmpty) ...[
                      _buildWelcome(selectedName ?? 'your senior'),
                      const SizedBox(height: 16),
                      _buildSuggestions(elderlyId, selectedName ?? 'the senior'),
                    ],
                    ...messages.map(_buildMessage),
                    if (agentState.isLoading) _buildTypingIndicator(),
                    if (pendingAction != null)
                      _buildActionCard(elderlyId, pendingAction, agentState.isLoading),
                  ],
                ),
        ),
        if (elderlyId.isNotEmpty) _buildComposer(elderlyId, agentState.isLoading),
      ],
    );
  }

  Widget _buildHeader(String elderlyId) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF1D4ED8), Color(0xFF4F46E5)]),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: Colors.white24,
            child: Icon(Icons.smart_toy_outlined, color: Colors.white),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('HomeCare Agent', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                SizedBox(height: 2),
                Text('Grounded in live care records and trusted guidance', style: TextStyle(color: Color(0xFFDBEAFE), fontSize: 11)),
              ],
            ),
          ),
          if (elderlyId.isNotEmpty)
            IconButton(
              tooltip: 'Clear this conversation',
              onPressed: () => ref.read(agentChatProvider.notifier).clearConversation(elderlyId),
              icon: const Icon(Icons.delete_outline, color: Colors.white),
            ),
        ],
      ),
    );
  }

  Widget _buildNoPatient() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.link_off, size: 48, color: Color(0xFF94A3B8)),
          SizedBox(height: 12),
          Text('Link and select a senior before using the agent.', textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildWelcome(String patientName) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Text(
        'Ask me about $patientName\'s medication, mood, tasks, health records, personalized health prediction or recent reports. I can also prepare a task, reminder, medication schedule or care report for you to confirm.',
        style: const TextStyle(color: Color(0xFF1E3A8A), height: 1.45),
      ),
    );
  }

  Widget _buildSuggestions(String elderlyId, String patientName) {
    final suggestions = [
      'Has $patientName taken medication today?',
      'What should I do if $patientName falls in the bathroom?',
      'How is $patientName doing today?',
      'What does $patientName\'s health prediction show?',
      'Create a care task for tomorrow at 9:00 AM.',
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: suggestions
          .map(
            (suggestion) => ActionChip(
              avatar: const Icon(Icons.auto_awesome, size: 16, color: Color(0xFF075DBB)),
              label: Text(suggestion, style: const TextStyle(fontSize: 12)),
              onPressed: () => _send(elderlyId, suggestion: suggestion),
            ),
          )
          .toList(),
    );
  }

  Widget _buildMessage(AgentChatMessage message) {
    final isUser = message.role == AgentMessageRole.user;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 520),
        margin: const EdgeInsets.only(top: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isUser ? const Color(0xFF075DBB) : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isUser ? 18 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 18),
          ),
          border: isUser ? null : Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: const [BoxShadow(color: Color(0x0F0F172A), blurRadius: 10, offset: Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.text,
              style: TextStyle(color: isUser ? Colors.white : const Color(0xFF0F172A), height: 1.42),
            ),
            if (message.sources.isNotEmpty) ...[
              const SizedBox(height: 10),
              const Divider(height: 1),
              const SizedBox(height: 8),
              Text(
                'Sources: ${message.sources.map((source) => source.title).join(' • ')}',
                style: const TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return const Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
            SizedBox(width: 10),
            Text('Reviewing care records…', style: TextStyle(color: Color(0xFF64748B))),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(String elderlyId, AgentPendingAction action, bool isLoading) {
    return Container(
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFCD34D)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.pending_actions, color: Color(0xFFD97706)),
              const SizedBox(width: 8),
              Expanded(child: Text(action.preview.title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16))),
              const Text('CONFIRM FIRST', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Color(0xFFD97706))),
            ],
          ),
          const SizedBox(height: 10),
          Text(action.preview.patientName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF92400E))),
          const SizedBox(height: 4),
          Text(action.preview.summary, style: const TextStyle(height: 1.4)),
          if (action.preview.details.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(action.preview.details, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: isLoading ? null : () => ref.read(agentChatProvider.notifier).cancelAction(elderlyId),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: isLoading
                      ? null
                      : () => ref.read(agentChatProvider.notifier).confirmAction(elderlyId),
                  icon: const Icon(Icons.check_circle_outline, size: 18),
                  label: const Text('Confirm'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildComposer(String elderlyId, bool isLoading) {
    return SafeArea(
      top: false,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFCBD5E1)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    enabled: !isLoading,
                    minLines: 1,
                    maxLines: 4,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _send(elderlyId),
                    decoration: const InputDecoration(
                      hintText: 'Ask about care or request an action…',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 6),
                    ),
                  ),
                ),
                IconButton.filled(
                  onPressed: isLoading ? null : () => _send(elderlyId),
                  icon: const Icon(Icons.arrow_upward_rounded),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(top: 6, bottom: 4),
            child: Text(
              'AI can make mistakes. For emergencies in Malaysia, call 999.',
              style: TextStyle(fontSize: 9, color: Color(0xFF94A3B8)),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
