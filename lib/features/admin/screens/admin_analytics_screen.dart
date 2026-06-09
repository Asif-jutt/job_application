import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/extensions.dart';
import '../../../core/widgets/rozgar_shell_body.dart';
import '../../../core/widgets/shimmer_skeleton.dart';
import '../provider/admin_provider.dart';
import '../widgets/admin_metric_tile.dart';
import '../widgets/registration_chart.dart';

class AdminAnalyticsScreen extends ConsumerWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(adminStatsProvider);

    return RozgarShellBody(
      child: statsAsync.when(
        loading: () => Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: List.generate(
              4,
              (_) => const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: ShimmerSkeleton(height: 72, borderRadius: 16),
              ),
            ),
          ),
        ),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (stats) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(adminStatsProvider);
            ref.invalidate(adminRegistrationChartProvider);
          },
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Platform Overview',
                style: context.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const RegistrationChart(),
              const SizedBox(height: 16),
              AdminMetricTile(
                label: 'Job Seekers',
                value: '${stats.totalUsers}',
                icon: Icons.person,
                color: context.colorScheme.primary,
              ),
              AdminMetricTile(
                label: 'Companies',
                value: '${stats.totalCompanies}',
                icon: Icons.business,
                color: context.colorScheme.secondary,
              ),
              AdminMetricTile(
                label: 'Active Jobs',
                value: '${stats.totalJobs}',
                icon: Icons.work,
                color: context.colorScheme.tertiary,
              ),
              AdminMetricTile(
                label: 'Applications',
                value: '${stats.totalApplications}',
                icon: Icons.assignment,
                color: Colors.deepPurple,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
