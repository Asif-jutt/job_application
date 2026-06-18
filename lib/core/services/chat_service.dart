import 'package:cloud_firestore/cloud_firestore.dart';

import '../constants/app_constants.dart';
import '../models/chat_message.dart';
import '../utils/app_logger.dart';
import 'firestore_service.dart';
import 'job_seed_service.dart';

class ChatService {
  ChatService(this._firestore);

  final FirestoreService _firestore;
  static const _chatIdDelimiter = '::';

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

  /// Finds or creates a chat between two users. Returns a stable Firestore doc id.
  Future<String> ensureChat({
    required String userId,
    required String otherUserId,
    String? title,
  }) async {
    final other = await _resolveRecruiterId(otherUserId);
    final participants = [userId, other]..sort();

    final existingId = await _findChatBetween(userId, other);
    if (existingId != null) {
      await _upsertChatDoc(existingId, participants, title);
      await _verifyMembership(existingId, userId);
      return existingId;
    }

    final legacyId = _legacyChatId(participants[0], participants[1]);
    final legacyDoc = await _firestore.chats.doc(legacyId).get();
    if (legacyDoc.exists) {
      await _upsertChatDoc(legacyId, participants, title);
      await _verifyMembership(legacyId, userId);
      return legacyId;
    }

    final newId = _firestore.chats.doc().id;
    await _upsertChatDoc(newId, participants, title, isNew: true);
    await _verifyMembership(newId, userId);
    AppLogger.info('Created chat $newId for $userId <-> $other');
    return newId;
  }

  /// Ensures [userId] can access [chatId]. Returns the canonical chat document id.
  Future<String> openChatForUser({
    required String chatId,
    required String userId,
    String? title,
  }) async {
    var activeId = chatId.trim();
    if (activeId.isEmpty) {
      throw StateError('Invalid chat id');
    }

    var doc = await _firestore.chats.doc(activeId).get();

    if (!doc.exists) {
      final otherId = resolveOtherParticipant(activeId, userId);
      if (otherId != null && otherId.isNotEmpty) {
        final resolved = await _resolveRecruiterId(otherId);
        final existing = await _findChatBetween(userId, resolved);
        if (existing != null) {
          activeId = existing;
          doc = await _firestore.chats.doc(activeId).get();
        } else {
          activeId = await ensureChat(
            userId: userId,
            otherUserId: resolved,
            title: title,
          );
          await _verifyMembership(activeId, userId);
          return activeId;
        }
      }
    }

    var participants = doc.exists
        ? List<String>.from(doc.data()?['participants'] as List? ?? [])
        : <String>[];

    if (!participants.contains(userId)) participants.add(userId);

    final otherId = resolveOtherParticipant(activeId, userId);
    if (otherId != null && otherId.isNotEmpty) {
      final resolved = await _resolveRecruiterId(otherId);
      if (!participants.contains(resolved)) participants.add(resolved);
      participants
        ..remove(otherId)
        ..remove(JobSeedService.seedCompanyId);
    }

    participants = await _normalizeParticipants(participants);
    if (!participants.contains(userId)) participants.add(userId);

    await _upsertChatDoc(
      activeId,
      participants,
      doc.data()?['title'] as String? ?? title,
      isNew: !doc.exists,
    );
    await _verifyMembership(activeId, userId);
    return activeId;
  }

  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String text,
    required List<String> participantIds,
  }) async {
    var participants = await _normalizeParticipants(participantIds);
    if (!participants.contains(senderId)) participants.add(senderId);

    await _firestore.chats.doc(chatId).set({
      'participants': participants,
      'lastMessage': text,
      'lastMessageAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await _verifyMembership(chatId, senderId);

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

  String? resolveOtherParticipant(String chatId, String currentUserId) {
    if (chatId.contains(_chatIdDelimiter)) {
      for (final id in chatId.split(_chatIdDelimiter)) {
        if (id.isNotEmpty && id != currentUserId) return id;
      }
      return null;
    }

    final prefix = '${currentUserId}_';
    final suffix = '_$currentUserId';
    if (chatId.startsWith(prefix)) {
      final other = chatId.substring(prefix.length);
      return other.isNotEmpty ? other : null;
    }
    if (chatId.endsWith(suffix)) {
      final other = chatId.substring(0, chatId.length - suffix.length);
      return other.isNotEmpty ? other : null;
    }

    final parts = chatId.split('_');
    if (parts.length >= 2) {
      for (final id in parts) {
        if (id.isNotEmpty && id != currentUserId) return id;
      }
    }
    return null;
  }

  String generateChatId(String userA, String userB) {
    final sorted = [userA, userB]..sort();
    return '${sorted[0]}$_chatIdDelimiter${sorted[1]}';
  }

  Future<String?> _findChatBetween(String userId, String otherUserId) async {
    try {
      final snapshot = await _firestore.chats
          .where('participants', arrayContains: userId)
          .get();

      for (final doc in snapshot.docs) {
        final parts =
            List<String>.from(doc.data()['participants'] as List? ?? []);
        if (parts.contains(otherUserId)) return doc.id;
      }
    } catch (e, st) {
      AppLogger.warning('Chat lookup failed', e);
      AppLogger.error('Chat lookup stack', st);
    }
    return null;
  }

  Future<void> _upsertChatDoc(
    String chatId,
    List<String> participants,
    String? title, {
    bool isNew = false,
  }) async {
    final normalized = await _normalizeParticipants(participants);
    final data = <String, dynamic>{
      'participants': normalized,
      'title': title ?? 'Conversation',
    };
    if (isNew) {
      data['lastMessage'] = '';
      data['lastMessageAt'] = FieldValue.serverTimestamp();
    }
    await _firestore.chats.doc(chatId).set(data, SetOptions(merge: true));
  }

  Future<void> _verifyMembership(String chatId, String userId) async {
    final doc = await _firestore.chats.doc(chatId).get();
    if (!doc.exists) {
      throw StateError('Chat document $chatId was not created');
    }
    final parts = List<String>.from(doc.data()?['participants'] as List? ?? []);
    if (!parts.contains(userId)) {
      throw StateError('User $userId is not a participant of chat $chatId');
    }
  }

  Future<List<String>> _normalizeParticipants(List<String> participants) async {
    final resolved = <String>[];
    for (final id in participants) {
      if (id.isEmpty) continue;
      resolved.add(await _resolveRecruiterId(id));
    }
    return resolved.toSet().toList()..sort();
  }

  Future<String> _resolveRecruiterId(String id) async {
    if (id != JobSeedService.seedCompanyId) return id;
    final recruiter = await _findCompanyRecruiterId();
    return recruiter ?? id;
  }

  Future<String?> _findCompanyRecruiterId() async {
    try {
      final snapshot = await _firestore.users
          .where('role', isEqualTo: 'company')
          .limit(1)
          .get();
      if (snapshot.docs.isEmpty) return null;
      return snapshot.docs.first.id;
    } catch (_) {
      return null;
    }
  }

  String _legacyChatId(String a, String b) {
    final sorted = [a, b]..sort();
    return '${sorted[0]}_${sorted[1]}';
  }
}
