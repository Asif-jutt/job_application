import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/job_model.dart';
import '../../../core/providers/core_providers.dart';
import '../../auth/provider/auth_provider.dart';

final userJobsProvider = FutureProvider<List<JobModel>>((ref) async {
  final firebaseUser = ref.watch(authStateProvider).value;
  if (firebaseUser == null) return [];

  final result = await ref.watch(jobRepositoryProvider).fetchHybridJobs();
  return result.when(
    success: (jobs) => jobs,
    failure: (message, _) => throw Exception(message),
  );
});
