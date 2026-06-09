import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/job_model.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/services/firestore_service.dart';
import '../../auth/provider/auth_provider.dart';

final companyJobsProvider = StreamProvider<List<JobModel>>((ref) {
  final user = ref.watch(authNotifierProvider).value;
  if (user == null) return Stream.value([]);

  return ref.watch(jobRepositoryProvider).watchFirestoreJobs().map(
        (jobs) => jobs.where((j) => j.companyId == user.uid).toList(),
      );
});

final companyPostJobProvider = Provider((ref) {
  return ref.watch(jobRepositoryProvider);
});

final companyJobRepositoryProvider = Provider<CompanyJobRepository>((ref) {
  return CompanyJobRepository(ref.watch(firestoreServiceProvider));
});

class CompanyJobRepository {
  CompanyJobRepository(this._firestore);
  final FirestoreService _firestore;

  Future<void> updateJob(String jobId, Map<String, dynamic> data) =>
      _firestore.updateJob(jobId, data);

  Future<void> deleteJob(String jobId) =>
      _firestore.jobs.doc(jobId).delete();
}
