// lib/features/caregiver/views/chat_view.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/models/models.dart';
import '../../auth/providers/auth_provider.dart';
import '../../family/providers/family_provider.dart';
import '../providers/caregiver_provider.dart';

class ChatView extends ConsumerStatefulWidget {
  const ChatView({super.key});
  @override
  ConsumerState<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends ConsumerState<ChatView> {
  Map<String, String>? _activeChannel;
  final _textController = TextEditingController();
  bool _hasAutoFetched = false;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  String _getDateHeader(DateTime messageDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final msgDate = DateTime(messageDate.year, messageDate.month, messageDate.day);
    
    if (msgDate == today) return 'TODAY';
    else if (msgDate == yesterday) return 'YESTERDAY';
    else return DateFormat('MMM d, yyyy').format(messageDate);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final currentUser = authState.user;
    final isFamily = currentUser?.role.toLowerCase() == 'family';
    final familyState = ref.watch(familyDashboardProvider);
    final caregiverState = ref.watch(caregiverProvider);
    
    final List<Map<String, String>> channelsList = isFamily ? familyState.linkedSeniors : caregiverState.assignedSeniors;
    final messages = isFamily ? familyState.currentChatMessages : caregiverState.currentChatMessages;
    final isLoading = isFamily ? familyState.isLoading : caregiverState.isLoading;
    final bool autoBypass = isFamily && channelsList.length == 1;
    final activeChannelData = _activeChannel ?? (autoBypass ? channelsList.first : null);

    if (autoBypass && !_hasAutoFetched && activeChannelData != null) {
      _hasAutoFetched = true;
      Future.microtask(() {
        ref.read(familyDashboardProvider.notifier).fetchChatMessages(activeChannelData['elderlyId']!);
      });
    }

    if (activeChannelData != null && messages.isNotEmpty) {
      final latestMsg = messages.last;
      final activeElderlyId = activeChannelData['elderlyId'] ?? '';
      
      if (isFamily && familyState.lastReadMessages[activeElderlyId] != latestMsg.id) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(familyDashboardProvider.notifier).markChatAsRead(activeElderlyId);
        });
      } else if (!isFamily && caregiverState.lastReadMessages[activeElderlyId] != latestMsg.id) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(caregiverProvider.notifier).markChatAsRead(activeElderlyId);
        });
      }
    }

    if (activeChannelData == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text('Care Communication Channels', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
          ),
          if (channelsList.isEmpty)
            Expanded(
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28), border: Border.all(color: const Color(0xFFE2E8F0))),
                  child: const Text('No linked senior channels available.\nPlease link a senior patient first.', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
                ),
              ),
            )
          else
            Expanded(
                child: ListView.separated(
                  itemCount: channelsList.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final senior = channelsList[index];
                    final elderlyId = senior['elderlyId'] ?? '';
                    
                    final String? lastReadId = isFamily 
                        ? familyState.lastReadMessages[elderlyId] 
                        : caregiverState.lastReadMessages[elderlyId];

                    int unreadCount = 0;
                    if (messages.isNotEmpty && messages.first.elderlyId == elderlyId) {
                      for (int i = messages.length - 1; i >= 0; i--) {
                        if (messages[i].id == lastReadId) break;
                        if (messages[i].senderId != currentUser?.id) unreadCount++;
                      }
                    } else {
                      unreadCount = lastReadId == null ? 1 : 0;
                    }

                    final bool hasUnread = unreadCount > 0;

                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: const BorderSide(color: Color(0xFFF1F5F9))),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            leading: CircleAvatar(
                              radius: 24,
                              backgroundColor: const Color(0xFFEFF6FF),
                              child: Text((senior['name'] ?? 'S').substring(0, 1).toUpperCase(), style: const TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold, fontSize: 18)),
                            ),
                            title: Text('Senior Channel: ${senior['name'] ?? "Senior Patient"}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                            subtitle: const Text('Tap to enter private care team chat', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                            trailing: const Icon(Icons.chevron_right, color: Color(0xFF2563EB)),
                            onTap: () {
                              setState(() => _activeChannel = senior);
                              if (elderlyId.isNotEmpty) {
                                if (isFamily) ref.read(familyDashboardProvider.notifier).fetchChatMessages(elderlyId);
                                else ref.read(caregiverProvider.notifier).fetchChatMessages(elderlyId);
                              }
                            },
                          ),
                        ),
                        if (hasUnread)
                          Positioned(
                            top: -4,
                            right: -4,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEF4444),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: Text(
                                '$unreadCount',
                                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
        ],
      );
    }

    final channelName = activeChannelData['name'] ?? 'Senior Patient';
    final activeElderlyId = activeChannelData['elderlyId'] ?? '';
    final reversedMessages = messages.reversed.toList();

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFF1F5F9))),
          child: Row(
            children: [
              if (!autoBypass)
                IconButton(icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A)), onPressed: () => setState(() => _activeChannel = null)),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('CHANNEL: $channelName', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                    const Text('Isolated Family & Caregiver Communication', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28), border: Border.all(color: const Color(0xFFF1F5F9))),
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : reversedMessages.isEmpty
                    ? const Center(
                        child: Text('No messages yet in this channel.\nType below to start communicating.', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600, fontSize: 13)),
                      )
                    : ListView.builder(
                        reverse: true,
                        itemCount: reversedMessages.length,
                        itemBuilder: (context, index) {
                          final msg = reversedMessages[index];
                          final isMe = msg.senderId == currentUser?.id;
                          bool showDateHeader = false;
                          
                          if (index == reversedMessages.length - 1) {
                            showDateHeader = true;
                          } else {
                            final prevMsg = reversedMessages[index + 1];
                            final prevDate = prevMsg.timestamp;
                            final currDate = msg.timestamp;
                            if (prevDate.year != currDate.year || prevDate.month != currDate.month || prevDate.day != currDate.day) {
                              showDateHeader = true;
                            }
                          }
                          
                          final timeString = DateFormat('h:mm a').format(msg.timestamp.toLocal());

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (showDateHeader)
                                Center(
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(vertical: 16),
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                    decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(12)),
                                    child: Text(_getDateHeader(msg.timestamp), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF64748B), letterSpacing: 0.5)),
                                  ),
                                ),
                              Align(
                                alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: isMe ? const Color(0xFF2563EB) : const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(20),
                                    border: isMe ? null : Border.all(color: const Color(0xFFE2E8F0)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                    children: [
                                      Text(msg.senderName, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isMe ? Colors.white70 : const Color(0xFF64748B))),
                                      const SizedBox(height: 2),
                                      Text(msg.text, style: TextStyle(color: isMe ? Colors.white : const Color(0xFF0F172A), fontWeight: FontWeight.w600, fontSize: 14)),
                                      const SizedBox(height: 4),
                                      Text(timeString, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: isMe ? Colors.white70 : const Color(0xFF94A3B8))),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _textController,
                decoration: InputDecoration(
                  hintText: 'Type message for $channelName care team...',
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                ),
              ),
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 26,
              backgroundColor: const Color(0xFF2563EB),
              child: IconButton(
                icon: const Icon(Icons.send, color: Colors.white, size: 20),
                onPressed: () async {
                  final text = _textController.text.trim();
                  if (text.isNotEmpty && activeElderlyId.isNotEmpty) {
                    final success = isFamily
                        ? await ref.read(familyDashboardProvider.notifier).sendChatMessage(elderlyId: activeElderlyId, messageText: text)
                        : await ref.read(caregiverProvider.notifier).sendChatMessage(elderlyId: activeElderlyId, messageText: text);
                    if (success) _textController.clear();
                  }
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}