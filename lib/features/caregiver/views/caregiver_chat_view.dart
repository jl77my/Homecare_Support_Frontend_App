import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../services/caregiver_service.dart';

class CaregiverChatView extends ConsumerStatefulWidget {
  final String receiverId;
  const CaregiverChatView({super.key, required this.receiverId});

  @override
  ConsumerState<CaregiverChatView> createState() => _CaregiverChatViewState();
}

class _CaregiverChatViewState extends ConsumerState<CaregiverChatView> {
  final _msgController = TextEditingController();
  final CaregiverService _service = CaregiverService();
  bool _isSending = false;

  void _sendMessage() async {
    final token = ref.read(authProvider).token;
    if (token == null || _msgController.text.trim().isEmpty) return;

    setState(() => _isSending = true);
    try {
      await _service.sendMessage(
        token: token,
        receiverId: widget.receiverId,
        messageText: _msgController.text.trim(),
      );

      if (!mounted) return;
      _msgController.clear();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Message Sent!")));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("In-App Chat")),
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
                    decoration: const InputDecoration(hintText: "Type a message..."),
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