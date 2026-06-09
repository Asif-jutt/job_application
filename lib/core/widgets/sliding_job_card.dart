import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../constants/app_constants.dart';
import '../models/job_model.dart';
import '../utils/extensions.dart';

class SlidingJobCard extends StatefulWidget {
  const SlidingJobCard({
    super.key,
    required this.job,
    required this.onTap,
    this.heroTag,
  });

  final JobModel job;
  final VoidCallback onTap;
  final String? heroTag;

  @override
  State<SlidingJobCard> createState() => _SlidingJobCardState();
}

class _SlidingJobCardState extends State<SlidingJobCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppConstants.animationDuration,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.05, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final job = widget.job;

    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _controller,
        child: Hero(
          tag: widget.heroTag ?? 'job_${job.id}',
          child: Material(
            color: Colors.transparent,
            child: Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              elevation: 2,
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: context.colorScheme.outline.withValues(alpha: 0.12),
                ),
              ),
              child: InkWell(
                onTap: widget.onTap,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (job.bannerUrl != null)
                      CachedNetworkImage(
                        imageUrl: job.bannerUrl!,
                        height: 120,
                        fit: BoxFit.cover,
                        placeholder: (_, _) => Container(
                          height: 120,
                          color: context.colorScheme.primaryContainer,
                        ),
                      )
                    else
                      Container(
                        height: 72,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              context.colorScheme.primary.withValues(alpha: 0.85),
                              context.colorScheme.secondary.withValues(alpha: 0.7),
                            ],
                          ),
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Align(
                          alignment: Alignment.bottomLeft,
                          child: Icon(
                            Icons.work_outline,
                            color: Colors.white.withValues(alpha: 0.9),
                            size: 28,
                          ),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  job.title,
                                  style: context.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              if (job.isPremium)
                                _Badge(
                                  label: 'Premium',
                                  color: context.colorScheme.tertiary,
                                )
                              else
                                _Badge(
                                  label: 'External',
                                  color: Colors.blueGrey,
                                ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            job.company,
                            style: context.textTheme.bodyMedium?.copyWith(
                              color: context.colorScheme.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Icon(Icons.location_on_outlined,
                                  size: 16, color: Colors.grey.shade600),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  job.location,
                                  style: context.textTheme.bodySmall,
                                ),
                              ),
                              if (job.salary != null)
                                Text(
                                  job.salary!,
                                  style: context.textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: context.colorScheme.primary,
                                  ),
                                ),
                            ],
                          ),
                          if (job.tags.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: job.tags.take(3).map((t) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: context.colorScheme.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(t, style: const TextStyle(fontSize: 11)),
                                );
                              }).toList(),
                            ),
                          ],
                          if (job.source == JobSource.firestore) ...[
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Icon(Icons.favorite_border,
                                    size: 14, color: Colors.grey.shade600),
                                const SizedBox(width: 4),
                                Text(
                                  '${job.likeCount}',
                                  style: context.textTheme.labelSmall,
                                ),
                                const SizedBox(width: 12),
                                Icon(Icons.chat_bubble_outline,
                                    size: 14, color: Colors.grey.shade600),
                                const SizedBox(width: 4),
                                Text(
                                  '${job.commentCount}',
                                  style: context.textTheme.labelSmall,
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
