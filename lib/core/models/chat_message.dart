import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

enum MessageStatus { sent, delivered, read }

class ChatMessage extends Equatable {
  const ChatMessage({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.text,
    required this.createdAt,
    this.status = MessageStatus.sent,
  });

  final String id;
  final String chatId;
  final String senderId;
  final String text;
  final DateTime createdAt;
  final MessageStatus status;

  factory ChatMessage.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
    String chatId,
  ) {
    final data = doc.data()!;
    return ChatMessage(
      id: doc.id,
      chatId: chatId,
      senderId: data['senderId'] as String? ?? '',
      text: data['text'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: MessageStatus.values.firstWhere(
        (s) => s.name == data['status'],
        orElse: () => MessageStatus.sent,
      ),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'senderId': senderId,
        'text': text,
        'createdAt': Timestamp.fromDate(createdAt),
        'status': status.name,
      };

  ChatMessage copyWith({MessageStatus? status}) => ChatMessage(
        id: id,
        chatId: chatId,
        senderId: senderId,
        text: text,
        createdAt: createdAt,
        status: status ?? this.status,
      );

  @override
  List<Object?> get props => [id, chatId, senderId, text, createdAt, status];
}
