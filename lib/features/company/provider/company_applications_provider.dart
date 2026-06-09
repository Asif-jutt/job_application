import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../../auth/provider/auth_provider.dart';
import '../../user/model/job_application.dart';

final companyApplicationsProvider = StreamProvider<List<JobApplication>>((ref) {
  final user = ref.watch(authNotifierProvider).value;
  if (user == null) return Stream.value([]);

  return ref.watch(firestoreServiceProvider).applications.snapshots().map(
        (snapshot) {
      final apps = snapshot.docs
          .map(JobApplication.fromFirestore)
          .where((app) =>
              app.companyId == user.uid ||
              (app.companyId == null &&
                  app.companyName == (user.displayName ?? '')))
          .toList();
      apps.sort(
        (a, b) => (b.appliedAt ?? DateTime(2000))
            .compareTo(a.appliedAt ?? DateTime(2000)),
      );
      return apps;
    },
  );
});
