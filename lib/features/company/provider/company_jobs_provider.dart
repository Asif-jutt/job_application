import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/job_model.dart';
import '../../../core/providers/core_providers.dart';
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
