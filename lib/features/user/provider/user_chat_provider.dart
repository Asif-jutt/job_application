import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/chat_message.dart';
import '../../../core/providers/core_providers.dart';
import '../../auth/provider/auth_provider.dart';

final userChatMessagesProvider =
    StreamProvider.family<List<ChatMessage>, String>((ref, chatId) {
  final user = ref.watch(authNotifierProvider).value;
  if (user == null) {
    return const Stream.empty();
  }
  return ref.read(chatServiceProvider).watchMessages(chatId);
});

final userChatsProvider = StreamProvider((ref) {
  final user = ref.watch(authNotifierProvider).value;
  if (user == null) return Stream.value([]);

  return ref
      .watch(firestoreServiceProvider)
      .chatsForUser(user.uid)
      .snapshots()
      .map((snapshot) {
        final docs = snapshot.docs.toList();
        docs.sort((a, b) {
          final aTime = a.data()['lastMessageAt'];
          final bTime = b.data()['lastMessageAt'];
          if (aTime is Timestamp && bTime is Timestamp) {
            return bTime.compareTo(aTime);
          }
          return 0;
        });
        return docs;
      });
});
