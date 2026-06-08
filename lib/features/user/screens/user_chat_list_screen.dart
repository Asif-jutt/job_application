import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/route_constants.dart';
import '../../../core/providers/core_providers.dart';

class UserChatListScreen extends ConsumerWidget {
  const UserChatListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final firestore = ref.watch(firestoreServiceProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Messages')),
      body: StreamBuilder(
        stream: firestore.chats
            .orderBy('lastMessageAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final chats = snapshot.data?.docs ?? [];
          if (chats.isEmpty) {
            return const Center(child: Text('No conversations yet'));
          }
          return ListView.builder(
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chat = chats[index];
              final data = chat.data();
              return ListTile(
                leading: CircleAvatar(
                  child: Text(
                    (data['lastMessage'] as String? ?? 'C')[0].toUpperCase(),
                  ),
                ),
                title: Text(data['lastMessage'] as String? ?? 'Chat'),
                subtitle: Text(
                  data['lastMessage'] as String? ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () => context.push(
                  RouteConstants.userChat.replaceAll(':chatId', chat.id),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
