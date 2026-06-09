import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/chat_message.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/utils/extensions.dart';
import '../../../core/widgets/async_error_view.dart';
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
  bool _initializing = true;
  String? _initError;

  @override
  void initState() {
    super.initState();
    _ensureChatReady();
  }

  Future<void> _ensureChatReady() async {
    final user = ref.read(authNotifierProvider).value;
    if (user == null) {
      if (mounted) {
        setState(() {
          _initializing = false;
          _initError = 'Please sign in to use chat';
        });
      }
      return;
    }

    try {
      final chatDoc = await ref
          .read(firestoreServiceProvider)
          .chats
          .doc(widget.chatId)
          .get();

      if (!chatDoc.exists) {
        final parts = widget.chatId.split('_');
        if (parts.length == 2 && parts.contains(user.uid)) {
          final otherId = parts.firstWhere((id) => id != user.uid);
          await ref.read(chatServiceProvider).ensureChat(
                userId: user.uid,
                otherUserId: otherId,
                title: 'Conversation',
              );
        }
      }
      if (mounted) setState(() => _initializing = false);
    } catch (e) {
      if (mounted) {
        setState(() {
          _initializing = false;
          _initError = 'Could not open chat. Pull to retry.';
        });
      }
    }
  }

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

    try {
      final chatService = ref.read(chatServiceProvider);
      final chatDoc = await ref
          .read(firestoreServiceProvider)
          .chats
          .doc(widget.chatId)
          .get();
      final participants = List<String>.from(
        chatDoc.data()?['participants'] as List? ?? [user.uid],
      );
      if (!participants.contains(user.uid)) participants.add(user.uid);

      await chatService.sendMessage(
        chatId: widget.chatId,
        senderId: user.uid,
        text: text,
        participantIds: participants,
      );

      _messageController.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_friendlyChatError(e)),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  String _friendlyChatError(Object error) {
    final msg = error.toString().toLowerCase();
    if (msg.contains('permission') || msg.contains('denied')) {
      return 'Chat access denied. Please sign in again and retry.';
    }
    return 'Failed to send message. Please try again.';
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
    if (_initializing) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chat')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_initError != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chat')),
        body: AsyncErrorView(
          message: _initError!,
          icon: Icons.chat_bubble_outline,
          onRetry: () {
            setState(() {
              _initializing = true;
              _initError = null;
            });
            _ensureChatReady();
          },
        ),
      );
    }

    final messagesAsync = ref.watch(userChatMessagesProvider(widget.chatId));
    final currentUser = ref.watch(authNotifierProvider).value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat'),
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: messagesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => AsyncErrorView(
                message: _friendlyChatError(e),
                icon: Icons.lock_outline,
                onRetry: () =>
                    ref.invalidate(userChatMessagesProvider(widget.chatId)),
              ),
              data: (messages) {
                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_outlined,
                          size: 48,
                          color: context.colorScheme.primary.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Start a conversation',
                          style: context.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Send a message below',
                          style: context.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  );
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
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
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
      padding: EdgeInsets.fromLTRB(
        12,
        12,
        12,
        12 + MediaQuery.paddingOf(context).bottom,
      ),
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
              decoration: InputDecoration(
                hintText: 'Type a message...',
                filled: true,
                fillColor: context.colorScheme.surfaceContainerHighest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSend(),
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: onSend,
            style: FilledButton.styleFrom(
              shape: const CircleBorder(),
              padding: const EdgeInsets.all(12),
            ),
            child: const Icon(Icons.send_rounded, size: 20),
          ),
        ],
      ),
    );
  }
}
