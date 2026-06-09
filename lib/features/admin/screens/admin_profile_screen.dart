import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/extensions.dart';
import '../../../core/widgets/profile_avatar_picker.dart';
import '../../auth/provider/auth_provider.dart';
import '../../user/provider/user_profile_provider.dart';

class AdminProfileScreen extends ConsumerStatefulWidget {
  const AdminProfileScreen({super.key});

  @override
  ConsumerState<AdminProfileScreen> createState() => _AdminProfileScreenState();
}

class _AdminProfileScreenState extends ConsumerState<AdminProfileScreen> {
  bool _isEditing = false;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authNotifierProvider).value;
    final profileAsync = ref.watch(userProfileProvider);

    if (user == null) {
      return const Center(child: Text('Loading profile...'));
    }

    return profileAsync.when(
      loading: () => const Center(child: Text('Loading profile...')),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (profile) {
        final photoUrl = profile?.photoUrl ?? user.photoUrl;
        final displayName = profile?.displayName ?? user.displayName ?? 'Admin';

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 80, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Admin Profile',
                      style: context.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (!_isEditing)
                    FilledButton.icon(
                      onPressed: () => setState(() => _isEditing = true),
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text('Edit'),
                    )
                  else
                    TextButton(
                      onPressed: () => setState(() => _isEditing = false),
                      child: const Text('Done'),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              Center(
                child: _isEditing
                    ? ProfileAvatarPicker(
                        photoUrl: photoUrl,
                        displayName: displayName,
                        radius: 56,
                        onUploaded: (url) async {
                          await ref
                              .read(userProfileRepositoryProvider)
                              .saveProfile(uid: user.uid, photoUrl: url);
                          ref.invalidate(userProfileProvider);
                        },
                      )
                    : CircleAvatar(
                        radius: 56,
                        backgroundColor: context.colorScheme.primaryContainer,
                        backgroundImage:
                            photoUrl != null ? NetworkImage(photoUrl) : null,
                        child: photoUrl == null
                            ? Text(
                                displayName[0].toUpperCase(),
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: context.colorScheme.primary,
                                ),
                              )
                            : null,
                      ),
              ),
              const SizedBox(height: 24),
              _InfoRow(label: 'Name', value: displayName),
              _InfoRow(label: 'Email', value: user.email),
              _InfoRow(label: 'Role', value: 'Administrator'),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: () =>
                    ref.read(authNotifierProvider.notifier).signOut(),
                icon: const Icon(Icons.logout),
                label: const Text('Sign Out'),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: context.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(value, style: context.textTheme.bodyLarge),
        ],
      ),
    );
  }
}
