import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../services/family_service.dart';

class FamilyChatView extends ConsumerStatefulWidget {
  final String caregiverId;
  const FamilyChatView({super.key, required this.caregiverId});

  @override
  ConsumerState<FamilyChatView> createState() => _FamilyChatViewState();
}

class _FamilyChatViewState extends ConsumerState<FamilyChatView> {
  final _msgController = TextEditingController();
  final FamilyService _service = FamilyService();
  bool _isSending = false;

  void _sendMessage() async {
    final token = ref.read(authProvider).token;
    if (token == null || _msgController.text.trim().isEmpty) return;

    setState(() => _isSending = true);
    try {
      await _service.sendMessage(
        token: token,
        receiverId: widget.caregiverId,
        messageText: _msgController.text.trim(),
      );

      if (!mounted) return;
      _msgController.clear();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Message Sent to Caregiver!")));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Chat with Caregiver")),
      body: Column(
        children: [
          const Expanded(child: Center(child: Text("Conversation History"))),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _msgController,
                    decoration: const InputDecoration(hintText: "Ask caregiver a question..."),
                  ),
                ),
                IconButton(
                  icon: _isSending ? const CircularProgressIndicator() : const Icon(Icons.send),
                  onPressed: _isSending ? null : _sendMessage,
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}