import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/extensions.dart';
import '../../../core/widgets/profile_avatar_picker.dart';
import '../../../core/widgets/profile_page_layout.dart';
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

        return ProfilePageLayout(
          title: 'Admin Profile',
          actions: [
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
          header: ProfileHeroCard(
            avatar: _isEditing
                ? ProfileAvatarPicker(
                    photoUrl: photoUrl,
                    displayName: displayName,
                    radius: 48,
                    onUploaded: (url) async {
                      await ref
                          .read(userProfileRepositoryProvider)
                          .saveProfile(uid: user.uid, photoUrl: url);
                      ref.invalidate(userProfileProvider);
                    },
                  )
                : CircleAvatar(
                    radius: 48,
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
            name: displayName,
            subtitle: user.email,
            badge: Chip(
              avatar: const Icon(Icons.admin_panel_settings, size: 16),
              label: const Text('Administrator'),
              backgroundColor: context.colorScheme.errorContainer,
              visualDensity: VisualDensity.compact,
            ),
          ),
          body: Column(
            children: [
              ProfileSectionCard(
                title: 'Account Details',
                icon: Icons.person_outline,
                child: Column(
                  children: [
                    _InfoRow(label: 'Name', value: displayName),
                    const Divider(height: 24),
                    _InfoRow(label: 'Email', value: user.email),
                    const Divider(height: 24),
                    _InfoRow(label: 'Role', value: 'Administrator'),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () =>
                      ref.read(authNotifierProvider.notifier).signOut(),
                  icon: const Icon(Icons.logout),
                  label: const Text('Sign Out'),
                ),
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: context.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: context.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          child: Text(value, style: context.textTheme.bodyLarge),
        ),
      ],
    );
  }
}
