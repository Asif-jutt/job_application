import 'package:flutter/material.dart';

import '../../../core/models/job_model.dart';
import '../../../core/utils/extensions.dart';
import '../widgets/job_detail_header.dart';

class UserJobDetailScreen extends StatelessWidget {
  const UserJobDetailScreen({super.key, required this.job});

  final JobModel job;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Job Details')),
      body: Hero(
        tag: 'job_${job.id}',
        child: Material(
          color: Colors.transparent,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                JobDetailHeader(job: job),
                const SizedBox(height: 24),
                Text(
                  'Description',
                  style: context.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(job.description, style: context.textTheme.bodyLarge),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () {},
                  child: const Text('Apply Now'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
