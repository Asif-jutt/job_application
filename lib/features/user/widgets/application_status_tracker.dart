import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/l10n/locale_provider.dart';
import '../../../core/utils/extensions.dart';
import '../../../core/widgets/async_error_view.dart';
import '../model/job_application.dart';
import '../provider/application_provider.dart';

/// Multi-step horizontal progress tracker for job application status.
/// Updates in real-time via Firestore `/applications/{id}` stream.
class ApplicationStatusTracker extends ConsumerWidget {
  const ApplicationStatusTracker({
    super.key,
    required this.applicationId,
    this.compact = false,
    this.fallbackStatus,
  });

  final String applicationId;
  final bool compact;
  final ApplicationStatus? fallbackStatus;

  static const List<ApplicationStatus> _pipeline = [
    ApplicationStatus.applied,
    ApplicationStatus.underReview,
    ApplicationStatus.interviewScheduled,
    ApplicationStatus.offered,
  ];

  String _statusLabel(ApplicationStatus status, AppStrings s) =>
      switch (status) {
        ApplicationStatus.applied => s.statusApplied,
        ApplicationStatus.underReview => s.statusUnderReview,
        ApplicationStatus.interviewScheduled => s.statusInterview,
        ApplicationStatus.offered => s.statusOffered,
        ApplicationStatus.rejected => s.statusRejected,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final statusAsync = ref.watch(applicationStatusStreamProvider(applicationId));

    return statusAsync.when(
      loading: () => _buildShimmer(context),
      error: (_, _) {
        if (fallbackStatus != null) {
          return _buildTracker(context, fallbackStatus!, s);
        }
        if (compact) {
          return Row(
            children: [
              Icon(Icons.error_outline, size: 16, color: context.colorScheme.error),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  s.statusUnavailable,
                  style: context.textTheme.bodySmall,
                ),
              ),
              TextButton(
                onPressed: () => ref.invalidate(
                  applicationStatusStreamProvider(applicationId),
                ),
                child: Text(s.retry),
              ),
            ],
          );
        }
        return AsyncErrorView(
          message: s.unableLoadStatus,
          icon: Icons.timeline_outlined,
          onRetry: () => ref.invalidate(
            applicationStatusStreamProvider(applicationId),
          ),
        );
      },
      data: (current) {
        if (current == ApplicationStatus.rejected) {
          return _RejectedBanner(message: s.statusRejected);
        }
        return _buildTracker(context, current, s);
      },
    );
  }

  Widget _buildTracker(BuildContext context, ApplicationStatus current, AppStrings s) {
    final currentIndex = _pipeline.indexOf(current).clamp(0, _pipeline.length - 1);

    return Card(
      elevation: 0,
      color: context.colorScheme.primaryContainer.withValues(alpha: 0.3),
      child: Padding(
        padding: EdgeInsets.all(compact ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              s.applicationProgress,
              style: context.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: compact ? 12 : 16),
            Row(
              children: List.generate(_pipeline.length * 2 - 1, (index) {
                if (index.isOdd) {
                  final stepIndex = index ~/ 2;
                  final isCompleted = stepIndex < currentIndex;
                  return Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      height: 3,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: isCompleted
                            ? context.colorScheme.primary
                            : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }

                final stepIndex = index ~/ 2;
                final status = _pipeline[stepIndex];
                final isActive = stepIndex == currentIndex;
                final isCompleted = stepIndex < currentIndex;

                return _StepNode(
                  label: compact ? '' : _statusLabel(status, s),
                  icon: _iconFor(status),
                  isActive: isActive,
                  isCompleted: isCompleted,
                  color: context.colorScheme.primary,
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmer(BuildContext context) {
    return Container(
      height: compact ? 60 : 80,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  IconData _iconFor(ApplicationStatus status) => switch (status) {
        ApplicationStatus.applied => Icons.send_rounded,
        ApplicationStatus.underReview => Icons.rate_review_outlined,
        ApplicationStatus.interviewScheduled => Icons.event_available_outlined,
        ApplicationStatus.offered => Icons.celebration_outlined,
        ApplicationStatus.rejected => Icons.cancel_outlined,
      };
}

class _StepNode extends StatelessWidget {
  const _StepNode({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.isCompleted,
    required this.color,
  });

  final String label;
  final IconData icon;
  final bool isActive;
  final bool isCompleted;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final bgColor = isCompleted || isActive ? color : Colors.grey.shade300;
    final iconColor = isCompleted || isActive ? Colors.white : Colors.grey.shade600;

    return Column(
      children: [
        AnimatedScale(
          scale: isActive ? 1.15 : 1.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.elasticOut,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 350),
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
              boxShadow: isActive
                  ? [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 8)]
                  : null,
            ),
            child: Icon(icon, size: 16, color: iconColor),
          ),
        ),
        if (label.isNotEmpty) ...[
          const SizedBox(height: 6),
          SizedBox(
            width: 72,
            child: Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                color: isActive ? color : Colors.grey.shade600,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _RejectedBanner extends StatelessWidget {
  const _RejectedBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: context.colorScheme.error),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: context.colorScheme.onErrorContainer),
            ),
          ),
        ],
      ),
    );
  }
}
