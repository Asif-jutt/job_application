import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/services/toast_service.dart';
import '../../../core/widgets/rozgar_shell_body.dart';
import '../../../core/widgets/shimmer_skeleton.dart';
import '../../user/model/job_application.dart';
import '../../user/provider/application_provider.dart';
import '../../user/widgets/application_status_tracker.dart';
import '../provider/company_applications_provider.dart';

class CompanyApplicationsScreen extends ConsumerWidget {
  const CompanyApplicationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appsAsync = ref.watch(companyApplicationsProvider);

    return RozgarShellBody(
      child: appsAsync.when(
        loading: () => const JobListSkeleton(itemCount: 3),
        error: (e, _) => Center(child: Text('Error: $e')),
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
                                app.applicantName,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                              Text('${app.jobTitle} · ${app.experience} yrs'),
                              if (app.resumeUrl != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  'Resume uploaded',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                              const SizedBox(height: 12),
                              ApplicationStatusTracker(
                                applicationId: app.id,
                                compact: true,
                              ),
                              const SizedBox(height: 12),
                              _StatusActions(
                                applicationId: app.id,
                                current: app.status,
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

class _StatusActions extends ConsumerStatefulWidget {
  const _StatusActions({
    required this.applicationId,
    required this.current,
  });

  final String applicationId;
  final ApplicationStatus current;

  @override
  ConsumerState<_StatusActions> createState() => _StatusActionsState();
}

class _StatusActionsState extends ConsumerState<_StatusActions> {
  bool _updating = false;

  static const _nextStatuses = [
    ApplicationStatus.underReview,
    ApplicationStatus.interviewScheduled,
    ApplicationStatus.offered,
    ApplicationStatus.rejected,
  ];

  Future<void> _advance(ApplicationStatus status) async {
    setState(() => _updating = true);
    final result = await ref
        .read(applicationRepositoryProvider)
        .updateStatus(applicationId: widget.applicationId, status: status);
    setState(() => _updating = false);
    if (!mounted) return;
    result.when(
      success: (_) => ToastService.success(
        context,
        'Status updated to ${status.label}',
      ),
      failure: (msg, _) => ToastService.error(context, msg),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _nextStatuses.map((status) {
        final isCurrent = status == widget.current;
        return ActionChip(
          label: Text(status.label),
          avatar: isCurrent ? const Icon(Icons.check, size: 16) : null,
          onPressed: _updating || isCurrent ? null : () => _advance(status),
        );
      }).toList(),
    );
  }
}
