import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/route_constants.dart';
import '../../../core/widgets/shimmer_skeleton.dart';
import '../../../core/widgets/sliding_job_card.dart';
import '../provider/user_jobs_provider.dart';

class UserJobsScreen extends ConsumerWidget {
  const UserJobsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobsAsync = ref.watch(userJobsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Discover Jobs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(userJobsProvider),
          ),
        ],
      ),
      body: jobsAsync.when(
        loading: () => const JobListSkeleton(),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (jobs) {
          if (jobs.isEmpty) {
            return const Center(child: Text('No jobs available'));
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
