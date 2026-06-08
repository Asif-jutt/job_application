import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/chat_message.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/utils/extensions.dart';
import '../../auth/provider/auth_provider.dart';
import '../provider/user_chat_provider.dart';

class UserChatScreen extends ConsumerStatefulWidget {
  const UserChatScreen({super.key, required this.chatId});

  final String chatId;

  @override
  ConsumerState<UserChatScreen> createState() => _UserChatScreenState();
}

class _UserChatScreenState extends ConsumerState<UserChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  bool _loadingMore = false;

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final user = ref.read(authNotifierProvider).value;
    if (user == null) return;

    final chatService = ref.read(chatServiceProvider);
    await chatService.sendMessage(
      chatId: widget.chatId,
      senderId: user.uid,
      text: text,
      participantIds: [user.uid],
    );
    _messageController.clear();
  }

  Future<void> _loadMore(List<ChatMessage> messages) async {
    if (_loadingMore || messages.isEmpty) return;
    setState(() => _loadingMore = true);

    final chatService = ref.read(chatServiceProvider);
    await chatService.fetchOlderMessages(
      widget.chatId,
      messages.last.createdAt,
    );

    if (mounted) setState(() => _loadingMore = false);
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(userChatMessagesProvider(widget.chatId));
    final currentUser = ref.watch(authNotifierProvider).value;

    return Scaffold(
      appBar: AppBar(title: const Text('Chat')),
      body: Column(
        children: [
          Expanded(
            child: messagesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (messages) {
                if (messages.isEmpty) {
                  return const Center(child: Text('Start a conversation'));
                }
                return NotificationListener<ScrollNotification>(
                  onNotification: (notification) {
                    if (notification is ScrollEndNotification &&
                        _scrollController.position.pixels >=
                            _scrollController.position.maxScrollExtent - 50) {
                      _loadMore(messages);
                    }
                    return false;
                  },
                  child: ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    padding: const EdgeInsets.all(16),
                    itemCount: messages.length + (_loadingMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (_loadingMore && index == messages.length) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(8),
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        );
                      }
                      final message = messages[index];
                      final isMe = message.senderId == currentUser?.uid;
                      return _MessageBubble(message: message, isMe: isMe);
                    },
                  ),
                );
              },
            ),
          ),
          _MessageInput(
            controller: _messageController,
            onSend: _sendMessage,
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, required this.isMe});

  final ChatMessage message;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isMe
              ? context.colorScheme.primary
              : context.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        constraints: BoxConstraints(maxWidth: context.screenSize.width * 0.75),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              message.text,
              style: TextStyle(
                color: isMe ? Colors.white : context.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  message.createdAt.timeAgo,
                  style: TextStyle(
                    fontSize: 10,
                    color: isMe ? Colors.white70 : Colors.grey,
                  ),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  Icon(
                    _statusIcon(message.status),
                    size: 12,
                    color: Colors.white70,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _statusIcon(MessageStatus status) => switch (status) {
        MessageStatus.sent => Icons.check,
        MessageStatus.delivered => Icons.done_all,
        MessageStatus.read => Icons.done_all,
      };
}

class _MessageInput extends StatelessWidget {
  const _MessageInput({required this.controller, required this.onSend});

  final TextEditingController controller;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'Type a message...',
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16),
              ),
              onSubmitted: (_) => onSend(),
            ),
          ),
          IconButton(
            onPressed: onSend,
            icon: Icon(Icons.send_rounded, color: context.colorScheme.primary),
          ),
        ],
      ),
    );
  }
}
