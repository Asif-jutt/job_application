import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/job_model.dart';
import '../../../core/providers/core_providers.dart';

final userJobsProvider = FutureProvider<List<JobModel>>((ref) async {
  final result = await ref.watch(jobRepositoryProvider).fetchHybridJobs();
  return result.when(
    success: (jobs) => jobs,
    failure: (_, _) => [],
  );
});
