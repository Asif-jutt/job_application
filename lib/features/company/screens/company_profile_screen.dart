import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/toast_service.dart';
import '../../../core/utils/extensions.dart';
import '../../../core/widgets/profile_avatar_picker.dart';
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

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 80, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Company Profile',
                      style: context.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (!_isEditing)
                    FilledButton.icon(
                      onPressed: () {
                        _syncControllers(profile);
                        setState(() => _isEditing = true);
                      },
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text('Edit'),
                    )
                  else ...[
                    TextButton(
                      onPressed: () => setState(() => _isEditing = false),
                      child: const Text('Cancel'),
                    ),
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
                  ],
                ],
              ),
              const SizedBox(height: 20),
              Center(
                child: _isEditing
                    ? ProfileAvatarPicker(
                        photoUrl: profile.logoUrl,
                        displayName: profile.companyName,
                        radius: 56,
                        onUploaded: (url) async {
                          await ref
                              .read(companyProfileRepositoryProvider)
                              .saveProfile(uid: profile.uid, logoUrl: url);
                          ref.invalidate(companyProfileProvider);
                        },
                      )
                    : CircleAvatar(
                        radius: 56,
                        backgroundColor: context.colorScheme.secondaryContainer,
                        backgroundImage: profile.logoUrl != null
                            ? NetworkImage(profile.logoUrl!)
                            : null,
                        child: profile.logoUrl == null
                            ? Icon(
                                Icons.business,
                                size: 48,
                                color: context.colorScheme.secondary,
                              )
                            : null,
                      ),
              ),
              const SizedBox(height: 20),
              _Field(
                label: 'Company Name',
                value: profile.companyName,
                isEditing: _isEditing,
                controller: _nameController,
              ),
              _Field(
                label: 'Email',
                value: profile.email,
                isEditing: false,
              ),
              _Field(
                label: 'Industry',
                value: profile.industry ?? 'Not specified',
                isEditing: _isEditing,
                controller: _industryController,
              ),
              _Field(
                label: 'Website',
                value: profile.website ?? 'Not specified',
                isEditing: _isEditing,
                controller: _websiteController,
              ),
              _Field(
                label: 'About',
                value: profile.description ?? 'No description yet',
                isEditing: _isEditing,
                controller: _descriptionController,
                multiline: true,
              ),
              const SizedBox(height: 24),
              if (!_isEditing)
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

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.value,
    required this.isEditing,
    this.controller,
    this.multiline = false,
  });

  final String label;
  final String value;
  final bool isEditing;
  final TextEditingController? controller;
  final bool multiline;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: context.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          isEditing && controller != null
              ? TextFormField(
                  controller: controller,
                  maxLines: multiline ? 4 : 1,
                  decoration: InputDecoration(
                    hintText: label,
                    border: const OutlineInputBorder(),
                  ),
                )
              : Text(value, style: context.textTheme.bodyLarge),
        ],
      ),
    );
  }
}
