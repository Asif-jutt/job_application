import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../provider/admin_provider.dart';

class AdminJobsScreen extends ConsumerWidget {
  const AdminJobsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobsAsync = ref.watch(adminJobsProvider);

    return jobsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (snapshot) {
        final jobs = snapshot.docs;
        if (jobs.isEmpty) {
          return const Center(child: Text('No jobs posted'));
        }
        return ListView.builder(
          itemCount: jobs.length,
          itemBuilder: (context, index) {
            final data = jobs[index].data();
            return ListTile(
              leading: const Icon(Icons.work_outline),
              title: Text(data['title'] as String? ?? 'Untitled'),
              subtitle: Text(data['companyName'] as String? ?? ''),
              trailing: data['isPremium'] == true
                  ? const Chip(label: Text('Premium', style: TextStyle(fontSize: 10)))
                  : null,
            );
          },
        );
      },
    );
  }
}
