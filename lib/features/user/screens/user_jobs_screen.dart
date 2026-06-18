import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/route_constants.dart';
import '../../../core/constants/l10n/locale_provider.dart';
import '../../../core/widgets/async_error_view.dart';
import '../../../core/widgets/rozgar_shell_body.dart';
import '../../../core/widgets/shimmer_skeleton.dart';
import '../../../core/widgets/sliding_job_card.dart';
import '../provider/user_jobs_provider.dart';

class UserJobsScreen extends ConsumerWidget {
  const UserJobsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobsAsync = ref.watch(userJobsProvider);
    final s = ref.watch(stringsProvider);

    return RozgarShellBody(
      child: jobsAsync.when(
        loading: () => const JobListSkeleton(),
        error: (e, _) => AsyncErrorView(
          message: s.unableLoadJobs,
          onRetry: () => ref.invalidate(userJobsProvider),
        ),
        data: (jobs) {
          if (jobs.isEmpty) {
            return Center(child: Text(s.noJobsAvailable));
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(userJobsProvider),
            child: ListView.builder(
              itemCount: jobs.length,
              itemBuilder: (context, index) {
                final job = jobs[index];
                return SlidingJobCard(
                  job: job,
                  heroTag: 'job_${job.id}',
                  onTap: () => context.push(
                    RouteConstants.userJobDetail.replaceAll(':jobId', job.id),
                    extra: job,
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
