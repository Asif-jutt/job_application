import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/user_role.dart';
import '../../../core/providers/core_providers.dart';
import '../model/admin_stats.dart';

final adminStatsProvider = FutureProvider<AdminStats>((ref) async {
  final firestore = ref.watch(firestoreServiceProvider);

  final usersSnapshot = await firestore.users.get();
  final jobsSnapshot = await firestore.jobs.get();
  final appsSnapshot = await firestore.applications.get();

  var companies = 0;
  var users = 0;
  for (final doc in usersSnapshot.docs) {
    final role = doc.data()['role'] as String?;
    if (role == UserRole.company.value) {
      companies++;
    } else if (role == UserRole.user.value) {
      users++;
    }
  }

  return AdminStats(
    totalUsers: users,
    totalCompanies: companies,
    totalJobs: jobsSnapshot.docs.length,
    totalApplications: appsSnapshot.docs.length,
  );
});

final adminUsersProvider = StreamProvider((ref) {
  return ref.watch(firestoreServiceProvider).users.snapshots();
});

final adminJobsProvider = StreamProvider((ref) {
  return ref
      .watch(firestoreServiceProvider)
      .jobs
      .orderBy('postedAt', descending: true)
      .snapshots();
});
