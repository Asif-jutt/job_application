import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/chat_message.dart';
import '../../../core/providers/core_providers.dart';
import '../../auth/provider/auth_provider.dart';

final userChatMessagesProvider =
    StreamProvider.family<List<ChatMessage>, String>((ref, chatId) {
  final firebaseUser = ref.watch(authStateProvider).value;
  if (firebaseUser == null) {
    return Stream.error(
      Exception('Please sign in to view messages'),
    );
  }
  return ref.watch(chatServiceProvider).watchMessages(chatId);
});

final userChatsProvider = StreamProvider((ref) {
  final firebaseUser = ref.watch(authStateProvider).value;
  if (firebaseUser == null) return Stream.value([]);

  return ref.watch(firestoreServiceProvider).chats.snapshots().map((snapshot) {
    return snapshot.docs.where((doc) {
      final participants =
          List<String>.from(doc.data()['participants'] as List? ?? []);
      return participants.contains(firebaseUser.uid);
    }).toList();
  });
});
