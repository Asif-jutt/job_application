import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/async_error_view.dart';
import '../../../core/widgets/rozgar_shell_body.dart';
import '../../../core/widgets/shimmer_skeleton.dart';
import '../provider/application_provider.dart';
import '../widgets/application_status_tracker.dart';

class UserApplicationsScreen extends ConsumerWidget {
  const UserApplicationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appsAsync = ref.watch(userApplicationsProvider);

    return RozgarShellBody(
      child: appsAsync.when(
        loading: () => const JobListSkeleton(itemCount: 3),
        error: (e, _) => AsyncErrorView(
          message: 'Unable to load your applications',
          onRetry: () => ref.invalidate(userApplicationsProvider),
        ),
        data: (apps) {
          if (apps.isEmpty) {
            return const Center(child: Text('No applications yet'));
          }
          return AnimationLimiter(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: apps.length,
              itemBuilder: (context, index) {
                final app = apps[index];
                return AnimationConfiguration.staggeredList(
                  position: index,
                  duration: AppConstants.animationDuration,
                  child: SlideAnimation(
                    verticalOffset: 40,
                    child: FadeInAnimation(
                      child: Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                app.jobTitle,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                              Text(app.companyName),
                              const SizedBox(height: 12),
                              ApplicationStatusTracker(
                                applicationId: app.id,
                                compact: true,
                                fallbackStatus: app.status,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
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
