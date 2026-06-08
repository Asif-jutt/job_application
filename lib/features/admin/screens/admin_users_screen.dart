import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/user_role.dart';
import '../provider/admin_provider.dart';

class AdminUsersScreen extends ConsumerWidget {
  const AdminUsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(adminUsersProvider);

    return usersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (snapshot) {
        final users = snapshot.docs;
        if (users.isEmpty) {
          return const Center(child: Text('No users registered'));
        }
        return ListView.builder(
          itemCount: users.length,
          itemBuilder: (context, index) {
            final doc = users[index];
            final data = doc.data();
            final role = UserRole.fromString(data['role'] as String?);
            return ListTile(
              leading: CircleAvatar(child: Text(role.label[0])),
              title: Text(data['displayName'] as String? ?? 'Unknown'),
              subtitle: Text(data['email'] as String? ?? ''),
              trailing: Chip(
                label: Text(role.label, style: const TextStyle(fontSize: 11)),
              ),
            );
          },
        );
      },
    );
  }
}
