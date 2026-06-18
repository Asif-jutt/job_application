import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/toast_service.dart';
import '../../../core/utils/extensions.dart';
import '../../../core/widgets/profile_avatar_picker.dart';
import '../../../core/widgets/profile_page_layout.dart';
import '../../auth/provider/auth_provider.dart';
import '../model/company_profile.dart';
import '../provider/company_profile_provider.dart';

class CompanyProfileScreen extends ConsumerStatefulWidget {
  const CompanyProfileScreen({super.key});

  @override
  ConsumerState<CompanyProfileScreen> createState() =>
      _CompanyProfileScreenState();
}

class _CompanyProfileScreenState extends ConsumerState<CompanyProfileScreen> {
  bool _isEditing = false;
  bool _saving = false;
  final _nameController = TextEditingController();
  final _industryController = TextEditingController();
  final _websiteController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _industryController.dispose();
    _websiteController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _syncControllers(CompanyProfile profile) {
    _nameController.text = profile.companyName;
    _industryController.text = profile.industry ?? '';
    _websiteController.text = profile.website ?? '';
    _descriptionController.text = profile.description ?? '';
  }

  Future<void> _save() async {
    final user = ref.read(authNotifierProvider).value;
    if (user == null) return;

    setState(() => _saving = true);
    final result =
        await ref.read(companyProfileRepositoryProvider).saveProfile(
              uid: user.uid,
              companyName: _nameController.text.trim(),
              industry: _industryController.text.trim(),
              website: _websiteController.text.trim(),
              description: _descriptionController.text.trim(),
            );
    setState(() => _saving = false);

    if (!mounted) return;
    result.when(
      success: (_) {
        setState(() => _isEditing = false);
        ToastService.success(context, 'Company profile updated');
      },
      failure: (msg, _) => ToastService.error(context, msg),
    );
  }

  List<Widget> _editActions(CompanyProfile profile) {
    if (!_isEditing) {
      return [
        FilledButton.icon(
          onPressed: () {
            _syncControllers(profile);
            setState(() => _isEditing = true);
          },
          icon: const Icon(Icons.edit_outlined, size: 18),
          label: const Text('Edit'),
        ),
      ];
    }
    return [
      TextButton(
        onPressed: () => setState(() => _isEditing = false),
        child: const Text('Cancel'),
      ),
      const SizedBox(width: 4),
      FilledButton(
        onPressed: _saving ? null : _save,
        child: _saving
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Text('Save'),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(companyProfileProvider);

    return profileAsync.when(
      loading: () => const Center(child: Text('Loading profile...')),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (profile) {
        if (profile == null) {
          return const Center(child: Text('Loading profile...'));
        }

        return ProfilePageLayout(
          title: 'Company Profile',
          actions: _editActions(profile),
          header: ProfileHeroCard(
            avatar: _isEditing
                ? ProfileAvatarPicker(
                    photoUrl: profile.logoUrl,
                    displayName: profile.companyName,
                    radius: 48,
                    onUploaded: (url) async {
                      await ref
                          .read(companyProfileRepositoryProvider)
                          .saveProfile(uid: profile.uid, logoUrl: url);
                      ref.invalidate(companyProfileProvider);
                    },
                  )
                : CircleAvatar(
                    radius: 48,
                    backgroundColor: context.colorScheme.secondaryContainer,
                    backgroundImage: profile.logoUrl != null
                        ? NetworkImage(profile.logoUrl!)
                        : null,
                    child: profile.logoUrl == null
                        ? Icon(
                            Icons.business,
                            size: 40,
                            color: context.colorScheme.secondary,
                          )
                        : null,
                  ),
            name: profile.companyName,
            subtitle: profile.email,
            badge: profile.industry != null
                ? Chip(
                    avatar: const Icon(Icons.domain, size: 16),
                    label: Text(profile.industry!),
                    visualDensity: VisualDensity.compact,
                  )
                : null,
          ),
          body: Column(
            children: [
              ProfileSectionCard(
                title: 'Company Name',
                icon: Icons.business_outlined,
                child: _Field(
                  value: profile.companyName,
                  isEditing: _isEditing,
                  controller: _nameController,
                ),
              ),
              const SizedBox(height: 12),
              ProfileSectionCard(
                title: 'Email',
                icon: Icons.email_outlined,
                child: Text(profile.email),
              ),
              const SizedBox(height: 12),
              ProfileSectionCard(
                title: 'Industry',
                icon: Icons.category_outlined,
                child: _Field(
                  value: profile.industry ?? 'Not specified',
                  isEditing: _isEditing,
                  controller: _industryController,
                ),
              ),
              const SizedBox(height: 12),
              ProfileSectionCard(
                title: 'Website',
                icon: Icons.language_outlined,
                child: _Field(
                  value: profile.website ?? 'Not specified',
                  isEditing: _isEditing,
                  controller: _websiteController,
                ),
              ),
              const SizedBox(height: 12),
              ProfileSectionCard(
                title: 'About',
                icon: Icons.info_outline,
                child: _Field(
                  value: profile.description ?? 'No description yet',
                  isEditing: _isEditing,
                  controller: _descriptionController,
                  multiline: true,
                ),
              ),
              const SizedBox(height: 24),
              if (!_isEditing)
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

class _Field extends StatelessWidget {
  const _Field({
    required this.value,
    required this.isEditing,
    this.controller,
    this.multiline = false,
  });

  final String value;
  final bool isEditing;
  final TextEditingController? controller;
  final bool multiline;

  @override
  Widget build(BuildContext context) {
    if (isEditing && controller != null) {
      return TextFormField(
        controller: controller,
        maxLines: multiline ? 4 : 1,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
        ),
      );
    }
    return Text(value, style: context.textTheme.bodyLarge);
  }
}
