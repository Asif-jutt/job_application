import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/models/job_model.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/utils/app_logger.dart';
import '../model/job_comment.dart';

bool isFirestoreJobId(String jobId) => !jobId.startsWith('ext_');

final jobDetailStreamProvider =
    StreamProvider.family<JobModel?, String>((ref, jobId) {
  if (!isFirestoreJobId(jobId)) return Stream.value(null);

  return ref.watch(firestoreServiceProvider).jobs.doc(jobId).snapshots().map(
        (doc) => doc.exists ? JobModel.fromFirestore(doc) : null,
      );
});

final jobCommentsProvider =
    StreamProvider.family<List<JobComment>, String>((ref, jobId) {
  return ref
      .watch(firestoreServiceProvider)
      .jobComments(jobId)
      .orderBy('createdAt', descending: true)
      .limit(AppConstants.commentsPageSize)
      .snapshots()
      .map((s) => s.docs.map((d) => JobComment.fromFirestore(d, jobId)).toList());
});

final socialRepositoryProvider = Provider<SocialRepository>((ref) {
  return SocialRepository(ref.watch(firestoreServiceProvider));
});

class SocialRepository {
  SocialRepository(this._firestore);

  final FirestoreService _firestore;

  Future<void> toggleLike(String jobId, String userId, bool currentlyLiked) async {
    if (!isFirestoreJobId(jobId)) {
      throw Exception('Likes are only available on Rozgar premium jobs');
    }

    final jobRef = _firestore.jobs.doc(jobId);
    await FirebaseFirestore.instance.runTransaction((tx) async {
      final snap = await tx.get(jobRef);
      if (!snap.exists) {
        throw Exception('Job not found in Firestore');
      }
      final data = snap.data() ?? {};
      final likedBy = List<String>.from(data['likedBy'] as List? ?? []);
      if (currentlyLiked) {
        likedBy.remove(userId);
      } else if (!likedBy.contains(userId)) {
        likedBy.add(userId);
      }
      tx.update(jobRef, {
        'likedBy': likedBy,
        'likeCount': likedBy.length,
      });
    });
    AppLogger.info('Like toggled on job $jobId');
  }

  Future<void> addComment({
    required String jobId,
    required String authorId,
    required String authorName,
    required String text,
    String? parentId,
    String? taggedUser,
  }) async {
    if (!isFirestoreJobId(jobId)) {
      throw Exception('Comments are only available on Rozgar premium jobs');
    }

    final jobRef = _firestore.jobs.doc(jobId);
    final jobSnap = await jobRef.get();
    if (!jobSnap.exists) {
      throw Exception('Job document not found');
    }

    final comment = JobComment(
      id: '',
      jobId: jobId,
      authorId: authorId,
      authorName: authorName,
      text: text,
      createdAt: DateTime.now(),
      parentId: parentId,
      taggedUser: taggedUser,
    );

    await _firestore.jobComments(jobId).add(comment.toFirestore());
    await jobRef.update({
      'commentCount': FieldValue.increment(1),
    });
    AppLogger.info('Comment added on job $jobId');
  }
}
