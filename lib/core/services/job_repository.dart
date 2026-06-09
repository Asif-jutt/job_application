import '../constants/api_constants.dart';
import '../constants/app_constants.dart';
import '../models/job_model.dart';
import '../network/dio_client.dart';
import '../utils/app_logger.dart';
import '../utils/result.dart';
import 'firestore_service.dart';
import 'performance_service.dart';

/// Unified repository merging Firestore premium jobs with external REST API jobs.
class JobRepository {
  JobRepository({
    required FirestoreService firestore,
    required DioClient dioClient,
    required PerformanceService performance,
  })  : _firestore = firestore,
        _dio = dioClient,
        _performance = performance;

  final FirestoreService _firestore;
  final DioClient _dio;
  final PerformanceService _performance;

  Future<Result<List<JobModel>>> fetchHybridJobs() async {
    return _performance.trace('fetch_hybrid_jobs', () async {
      var firestoreJobs = <JobModel>[];
      var externalJobs = <JobModel>[];

      try {
        firestoreJobs = await _fetchFirestoreJobs();
      } catch (e, st) {
        AppLogger.severe('Firestore jobs fetch failed', e, st);
      }

      try {
        externalJobs = await _fetchExternalJobs();
      } catch (e) {
        AppLogger.warning('External jobs fetch failed', e);
      }

      if (firestoreJobs.isEmpty && externalJobs.isEmpty) {
        return const Failure(
          'Unable to load jobs. Check your connection and try again.',
        );
      }

      final combined = [...firestoreJobs, ...externalJobs];
      combined.sort((a, b) {
        if (a.isPremium != b.isPremium) return a.isPremium ? -1 : 1;
        final aDate = a.postedAt ?? DateTime(1970);
        final bDate = b.postedAt ?? DateTime(1970);
        return bDate.compareTo(aDate);
      });

      AppLogger.info(
        'Fetched ${firestoreJobs.length} premium + ${externalJobs.length} external jobs',
      );
      return Success(combined);
    });
  }

  Future<List<JobModel>> _fetchFirestoreJobs() async {
    final snapshot = await _firestore.jobs
        .orderBy('postedAt', descending: true)
        .limit(AppConstants.jobsPageSize)
        .get();

    return snapshot.docs.map(JobModel.fromFirestore).toList();
  }

  Future<List<JobModel>> _fetchExternalJobs() async {
    try {
      final response = await _dio.get<List<dynamic>>(
        ApiConstants.externalJobsEndpoint,
      );

      final data = response.data;
      if (data == null) return [];

      return data
          .take(10)
          .map((e) => JobModel.fromExternalApi(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      AppLogger.warning('External jobs fetch failed', e);
      return [];
    }
  }

  Future<Result<void>> postPremiumJob(JobModel job) async {
    return _performance.trace('post_premium_job', () async {
      try {
        await _firestore.jobs.add(job.toFirestore());
        return const Success(null);
      } catch (e, st) {
        AppLogger.severe('Post job failed', e, st);
        return Failure('Failed to post job', e);
      }
    });
  }

  Stream<List<JobModel>> watchFirestoreJobs() {
    return _firestore.jobs
        .orderBy('postedAt', descending: true)
        .limit(AppConstants.jobsPageSize)
        .snapshots()
        .map((s) => s.docs.map(JobModel.fromFirestore).toList());
  }
}
