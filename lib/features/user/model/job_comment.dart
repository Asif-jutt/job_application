import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class JobComment extends Equatable {
  const JobComment({
    required this.id,
    required this.jobId,
    required this.authorId,
    required this.authorName,
    required this.text,
    required this.createdAt,
    this.parentId,
    this.taggedUser,
    this.likeCount = 0,
  });

  final String id;
  final String jobId;
  final String authorId;
  final String authorName;
  final String text;
  final DateTime createdAt;
  final String? parentId;
  final String? taggedUser;
  final int likeCount;

  bool get isReply => parentId != null;

  factory JobComment.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
    String jobId,
  ) {
    final data = doc.data() ?? {};
    return JobComment(
      id: doc.id,
      jobId: jobId,
      authorId: data['authorId'] as String? ?? '',
      authorName: data['authorName'] as String? ?? 'User',
      text: data['text'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      parentId: data['parentId'] as String?,
      taggedUser: data['taggedUser'] as String?,
      likeCount: data['likeCount'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'authorId': authorId,
        'authorName': authorName,
        'text': text,
        'createdAt': Timestamp.fromDate(createdAt),
        'parentId': parentId,
        'taggedUser': taggedUser,
        'likeCount': likeCount,
      };

  @override
  List<Object?> get props => [id, jobId, authorId, text, parentId];
}
