import 'package:cloud_firestore/cloud_firestore.dart';

import '../constants/app_constants.dart';
import '../models/chat_message.dart';
import '../utils/app_logger.dart';
import 'firestore_service.dart';

class ChatService {
  ChatService(this._firestore);

  final FirestoreService _firestore;

  Stream<List<ChatMessage>> watchMessages(
    String chatId, {
    int limit = AppConstants.chatPageSize,
  }) {
    return _firestore
        .messages(chatId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChatMessage.fromFirestore(doc, chatId))
            .toList());
  }

  Future<List<ChatMessage>> fetchOlderMessages(
    String chatId,
    DateTime before, {
    int limit = AppConstants.chatPageSize,
  }) async {
    final snapshot = await _firestore
        .messages(chatId)
        .orderBy('createdAt', descending: true)
        .startAfter([Timestamp.fromDate(before)])
        .limit(limit)
        .get();

    return snapshot.docs
        .map((doc) => ChatMessage.fromFirestore(doc, chatId))
        .toList();
  }

  Future<String> ensureChat({
    required String userId,
    required String otherUserId,
    String? title,
  }) async {
    final chatId = generateChatId(userId, otherUserId);
    await _firestore.chats.doc(chatId).set({
      'participants': [userId, otherUserId],
      'title': title ?? 'Conversation',
      'lastMessage': '',
      'lastMessageAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    return chatId;
  }

  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String text,
    required List<String> participantIds,
  }) async {
    await _firestore.chats.doc(chatId).set({
      'participants': participantIds,
      'lastMessage': text,
      'lastMessageAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    final messageRef = _firestore.messages(chatId).doc();
    final message = ChatMessage(
      id: messageRef.id,
      chatId: chatId,
      senderId: senderId,
      text: text,
      createdAt: DateTime.now(),
      status: MessageStatus.sent,
    );

    await messageRef.set(message.toFirestore());
    AppLogger.info('Message sent to chat $chatId');
  }

  Future<void> markAsDelivered(String chatId, String messageId) =>
      _updateStatus(chatId, messageId, MessageStatus.delivered);

  Future<void> markAsRead(String chatId, String messageId) =>
      _updateStatus(chatId, messageId, MessageStatus.read);

  Future<void> _updateStatus(
    String chatId,
    String messageId,
    MessageStatus status,
  ) =>
      _firestore.messages(chatId).doc(messageId).update({
        'status': status.name,
      });

  String generateChatId(String userA, String userB) {
    final sorted = [userA, userB]..sort();
    return '${sorted[0]}_${sorted[1]}';
  }
}
