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
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _controller,
        child: Hero(
          tag: widget.heroTag ?? 'job_${widget.job.id}',
          child: Material(
            color: Colors.transparent,
            child: Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: InkWell(
                onTap: widget.onTap,
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              widget.job.title,
                              style: context.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (widget.job.isPremium)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: context.colorScheme.tertiary
                                    .withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Premium',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: context.colorScheme.tertiary,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        widget.job.company,
                        style: context.textTheme.bodyMedium?.copyWith(
                          color: context.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.location_on_outlined,
                              size: 16, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Text(widget.job.location,
                              style: context.textTheme.bodySmall),
                          if (widget.job.salary != null) ...[
                            const Spacer(),
                            Text(
                              widget.job.salary!,
                              style: context.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
