import 'package:flutter/material.dart';

import '../../../core/models/job_model.dart';
import '../../../core/utils/extensions.dart';

class JobDetailHeader extends StatelessWidget {
  const JobDetailHeader({super.key, required this.job});

  final JobModel job;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          job.title,
          style: context.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          job.company,
          style: context.textTheme.titleMedium?.copyWith(
            color: context.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: [
            _Chip(icon: Icons.location_on_outlined, label: job.location),
            if (job.salary != null)
              _Chip(icon: Icons.payments_outlined, label: job.salary!),
            _Chip(
              icon: job.isPremium ? Icons.star : Icons.public,
              label: job.isPremium ? 'Premium' : 'External',
            ),
          ],
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      visualDensity: VisualDensity.compact,
    );
  }
}
