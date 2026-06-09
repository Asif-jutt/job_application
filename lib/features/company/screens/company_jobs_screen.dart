import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/models/job_model.dart';
import '../../../core/services/toast_service.dart';
import '../../../core/utils/extensions.dart';
import '../../../core/widgets/rozgar_shell_body.dart';
import '../../user/widgets/comments_sheet.dart';
import '../provider/company_jobs_provider.dart';

class CompanyJobsScreen extends ConsumerWidget {
  const CompanyJobsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobsAsync = ref.watch(companyJobsProvider);

    return RozgarShellBody(
      child: jobsAsync.when(
        loading: () => const Center(child: Text('Loading jobs...')),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (jobs) {
          if (jobs.isEmpty) {
            return const Center(child: Text('No jobs posted yet'));
          }
          return AnimationLimiter(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: jobs.length,
              itemBuilder: (context, index) {
                final job = jobs[index];
                return AnimationConfiguration.staggeredList(
                  position: index,
                  duration: AppConstants.animationDuration,
                  child: SlideAnimation(
                    verticalOffset: 30,
                    child: FadeInAnimation(
                      child: _CompanyJobCard(job: job),
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

class _CompanyJobCard extends ConsumerWidget {
  const _CompanyJobCard({required this.job});
  final JobModel job;

  Future<void> _edit(BuildContext context, WidgetRef ref) async {
    final titleCtrl = TextEditingController(text: job.title);
    final descCtrl = TextEditingController(text: job.description);
    final locCtrl = TextEditingController(text: job.location);
    final salaryCtrl = TextEditingController(text: job.salary ?? '');

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Job'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              TextField(
                controller: descCtrl,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
              ),
              TextField(
                controller: locCtrl,
                decoration: const InputDecoration(labelText: 'Location'),
              ),
              TextField(
                controller: salaryCtrl,
                decoration: const InputDecoration(labelText: 'Salary'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (saved != true) return;

    await ref.read(companyJobRepositoryProvider).updateJob(job.id, {
      'title': titleCtrl.text.trim(),
      'description': descCtrl.text.trim(),
      'location': locCtrl.text.trim(),
      'salary': salaryCtrl.text.trim(),
    });
    if (context.mounted) {
      ToastService.success(context, 'Job updated');
    }
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Job?'),
        content: Text('Remove "${job.title}" permanently?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await ref.read(companyJobRepositoryProvider).deleteJob(job.id);
    if (context.mounted) {
      ToastService.success(context, 'Job deleted');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (job.bannerUrl != null)
            CachedNetworkImage(
              imageUrl: job.bannerUrl!,
              height: 100,
              fit: BoxFit.cover,
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  job.title,
                  style: context.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(job.location, style: context.textTheme.bodySmall),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.favorite_border,
                        size: 14, color: Colors.grey.shade600),
                    Text(' ${job.likeCount}  '),
                    Icon(Icons.chat_bubble_outline,
                        size: 14, color: Colors.grey.shade600),
                    Text(' ${job.commentCount}'),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => _edit(context, ref),
                      icon: const Icon(Icons.edit_outlined, size: 16),
                      label: const Text('Edit'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => showCommentsSheet(context, job.id),
                      icon: const Icon(Icons.comment_outlined, size: 16),
                      label: const Text('Comments'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _delete(context, ref),
                      icon: const Icon(Icons.delete_outline, size: 16),
                      label: const Text('Delete'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
