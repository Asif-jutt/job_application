import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/job_model.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/services/local_notification_service.dart';
import '../../../core/services/workmanager_service.dart';
import '../../../core/utils/app_logger.dart';
import '../../../core/utils/result.dart';
import '../../auth/provider/auth_provider.dart';
import '../model/job_application.dart';

final userApplicationsProvider = StreamProvider<List<JobApplication>>((ref) {
  final firebaseUser = ref.watch(authStateProvider).value;
  if (firebaseUser == null) return Stream.value([]);

  return ref
      .watch(firestoreServiceProvider)
      .applications
      .where('applicantId', isEqualTo: firebaseUser.uid)
      .snapshots()
      .map((s) {
    final apps = s.docs.map(JobApplication.fromFirestore).toList();
    apps.sort(
      (a, b) => (b.appliedAt ?? DateTime(2000))
          .compareTo(a.appliedAt ?? DateTime(2000)),
    );
    return apps;
  });
});

final applicationStatusStreamProvider =
    StreamProvider.family<ApplicationStatus, String>((ref, applicationId) {
  final firebaseUser = ref.watch(authStateProvider).value;
  if (firebaseUser == null || applicationId.isEmpty) {
    return Stream.value(ApplicationStatus.applied);
  }

  return ref
      .watch(firestoreServiceProvider)
      .applications
      .doc(applicationId)
      .snapshots()
      .map((doc) {
        if (!doc.exists) return ApplicationStatus.applied;
        return ApplicationStatus.fromString(doc.data()?['status'] as String?);
      });
});

final applicationRepositoryProvider = Provider<ApplicationRepository>((ref) {
  return ApplicationRepository(
    firestore: ref.watch(firestoreServiceProvider),
    workmanager: ref.watch(workmanagerServiceProvider),
    notifications: ref.watch(localNotificationProvider),
  );
});

class ApplicationRepository {
  ApplicationRepository({
    required FirestoreService firestore,
    required WorkmanagerService workmanager,
    required LocalNotificationService notifications,
  })  : _firestore = firestore,
        _workmanager = workmanager,
        _notifications = notifications;

  final FirestoreService _firestore;
  final WorkmanagerService _workmanager;
  final LocalNotificationService _notifications;

  Future<Result<String>> submitApplication({
    required JobModel job,
    required String applicantId,
    required String applicantName,
    required String experience,
    String? resumeUrl,
  }) async {
    try {
      final application = JobApplication(
        id: '',
        jobId: job.id,
        jobTitle: job.title,
        companyName: job.company,
        companyId: job.companyId,
        applicantId: applicantId,
        applicantName: applicantName,
        experience: experience,
        status: ApplicationStatus.applied,
        resumeUrl: resumeUrl,
        appliedAt: DateTime.now(),
      );

      final ref = await _firestore.addApplication(application.toFirestore());
      final applicationId = ref.id;

      await _firestore.applicationStatus(applicationId).add({
        'status': ApplicationStatus.applied.name,
        'label': ApplicationStatus.applied.label,
        'timestamp': FieldValue.serverTimestamp(),
      });

      await _workmanager.scheduleDecryptTask({
        'type': 'application_submitted',
        'applicationId': applicationId,
      });

      await _notifications.showApplicationNotification(
        title: 'Application Submitted',
        body: 'Your application for ${job.title} was sent successfully.',
        payload: applicationId,
      );

      AppLogger.info('Application submitted: $applicationId');
      return Success(applicationId);
    } catch (e, st) {
      AppLogger.severe('Application submission failed', e, st);
      return Failure('Failed to submit application', e);
    }
  }

  Future<Result<void>> updateStatus({
    required String applicationId,
    required ApplicationStatus status,
  }) async {
    try {
      await _firestore.updateApplication(applicationId, {
        'status': status.name,
      });
      await _firestore.applicationStatus(applicationId).add({
        'status': status.name,
        'label': status.label,
        'timestamp': FieldValue.serverTimestamp(),
      });
      AppLogger.info('Application $applicationId → ${status.name}');
      return const Success(null);
    } catch (e, st) {
      AppLogger.severe('Status update failed', e, st);
      return Failure('Failed to update status', e);
    }
  }
}
