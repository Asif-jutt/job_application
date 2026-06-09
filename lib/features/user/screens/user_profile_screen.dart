import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/providers/core_providers.dart';
import '../../../core/services/cloudinary_service.dart';
import '../../../core/services/toast_service.dart';
import '../../../core/utils/extensions.dart';
import '../../../core/widgets/profile_avatar_picker.dart';
import '../../auth/provider/auth_provider.dart';
import '../constants/user_constants.dart';
import '../model/user_profile.dart';
import '../provider/user_profile_provider.dart';

class UserProfileScreen extends ConsumerStatefulWidget {
  const UserProfileScreen({super.key});

  @override
  ConsumerState<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends ConsumerState<UserProfileScreen> {
  final _salaryController = TextEditingController();
  final _headlineController = TextEditingController();
  final _skillsController = TextEditingController();
  final _eduInstitutionController = TextEditingController();
  final _eduDegreeController = TextEditingController();
  final _eduYearController = TextEditingController();
  final _expCompanyController = TextEditingController();
  final _expRoleController = TextEditingController();
  final _expDurationController = TextEditingController();
  bool _isEditing = false;
  bool _uploading = false;
  bool _saving = false;

  @override
  void dispose() {
    _salaryController.dispose();
    _headlineController.dispose();
    _skillsController.dispose();
    _eduInstitutionController.dispose();
    _eduDegreeController.dispose();
    _eduYearController.dispose();
    _expCompanyController.dispose();
    _expRoleController.dispose();
    _expDurationController.dispose();
    super.dispose();
  }

  void _syncControllers(UserProfile profile) {
    _headlineController.text = profile.headline ?? '';
    _salaryController.text = profile.salary ?? '';
    _skillsController.text = profile.skills.join(', ');
    if (profile.education.isNotEmpty) {
      final e = profile.education.first;
      _eduInstitutionController.text = e.institution;
      _eduDegreeController.text = e.degree;
      _eduYearController.text = e.year;
    }
    if (profile.experience.isNotEmpty) {
      final x = profile.experience.first;
      _expCompanyController.text = x.company;
      _expRoleController.text = x.role;
      _expDurationController.text = x.duration;
    }
  }

  Future<void> _uploadCv() async {
    final permission = ref.read(permissionServiceProvider);
    final result = await permission.requestMediaForUpload();
    if (result.isFailure) {
      if (mounted) {
        ToastService.error(
          context,
          result.when(success: (_) => '', failure: (m, _) => m),
        );
      }
      return;
    }

    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;

    final user = ref.read(authNotifierProvider).value;
    if (user == null) return;

    setState(() => _uploading = true);
    final uploadResult =
        await ref.read(cloudinaryServiceProvider).uploadFromXFile(
              file,
              type: CloudinaryUploadType.resume,
            );
    setState(() => _uploading = false);

    if (!mounted) return;
    if (uploadResult.isFailure) {
      uploadResult.when(
        success: (_) {},
        failure: (msg, _) => ToastService.error(context, msg),
      );
      return;
    }

    final url = uploadResult.when(success: (v) => v, failure: (_, _) => '');
    final save = await ref.read(userProfileRepositoryProvider).saveProfile(
          uid: user.uid,
          cvUrl: url,
        );
    if (!mounted) return;
    save.when(
      success: (_) => ToastService.success(context, 'CV uploaded successfully'),
      failure: (msg, _) => ToastService.error(context, msg),
    );
  }

  Future<void> _saveProfile() async {
    final user = ref.read(authNotifierProvider).value;
    if (user == null) return;

    final skills = _skillsController.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    final education = [
      if (_eduDegreeController.text.trim().isNotEmpty)
        EducationEntry(
          institution: _eduInstitutionController.text.trim(),
          degree: _eduDegreeController.text.trim(),
          year: _eduYearController.text.trim(),
        ).toMap(),
    ];

    final experience = [
      if (_expRoleController.text.trim().isNotEmpty)
        WorkExperience(
          company: _expCompanyController.text.trim(),
          role: _expRoleController.text.trim(),
          duration: _expDurationController.text.trim(),
        ).toMap(),
    ];

    setState(() => _saving = true);
    final result = await ref.read(userProfileRepositoryProvider).saveProfile(
          uid: user.uid,
          headline: _headlineController.text.trim(),
          salary: _salaryController.text.trim(),
          skills: skills,
          education: education,
          experience: experience,
        );
    setState(() => _saving = false);

    if (!mounted) return;
    result.when(
      success: (_) {
        setState(() => _isEditing = false);
        ToastService.success(context, 'Profile saved (salary encrypted)');
      },
      failure: (msg, _) => ToastService.error(context, msg),
    );
  }

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
      data: (stored) {
        final profile = stored ??
            UserProfile(
              uid: user.uid,
              displayName: user.displayName ?? 'User',
              email: user.email,
              phone: user.phone,
              photoUrl: user.photoUrl,
            );

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 80, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'My Profile',
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
                      onPressed: _saving ? null : _saveProfile,
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
              const SizedBox(height: 16),
              _ProfileHeader(
                profile: profile,
                isEditing: _isEditing,
                onPhotoUploaded: (url) async {
                  await ref.read(userProfileRepositoryProvider).saveProfile(
                        uid: user.uid,
                        photoUrl: url,
                      );
                  ref.invalidate(userProfileProvider);
                },
              ),
              const SizedBox(height: 24),
              _sectionTitle(context, 'About'),
              _isEditing
                  ? TextFormField(
                      controller: _headlineController,
                      decoration: const InputDecoration(
                        hintText: 'Professional headline',
                        prefixIcon: Icon(Icons.info_outline),
                      ),
                    )
                  : Text(profile.headline ?? 'No headline yet'),
              const SizedBox(height: 24),
              _sectionTitle(context, UserConstants.salaryLabel),
              _isEditing
                  ? TextFormField(
                      controller: _salaryController,
                      decoration: const InputDecoration(
                        hintText: 'Expected compensation (encrypted)',
                        prefixIcon: Icon(Icons.payments_outlined),
                        helperText: 'AES-256 CTR encrypted before Firestore write',
                      ),
                    )
                  : Text(
                      profile.salary?.isNotEmpty == true
                          ? profile.salary!
                          : 'Not specified',
                    ),
              const SizedBox(height: 24),
              _sectionTitle(context, 'Skills'),
              _isEditing
                  ? TextFormField(
                      controller: _skillsController,
                      decoration: const InputDecoration(
                        hintText: 'Flutter, Firebase, Dart (comma separated)',
                        prefixIcon: Icon(Icons.star_outline),
                      ),
                    )
                  : profile.skills.isEmpty
                      ? const Text('No skills added yet')
                      : Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: profile.skills
                              .map((s) => Chip(label: Text(s)))
                              .toList(),
                        ),
              const SizedBox(height: 24),
              _sectionTitle(context, 'Education'),
              _isEditing
                  ? Column(
                      children: [
                        TextFormField(
                          controller: _eduInstitutionController,
                          decoration: const InputDecoration(
                            labelText: 'Institution',
                            prefixIcon: Icon(Icons.school_outlined),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _eduDegreeController,
                          decoration: const InputDecoration(
                            labelText: 'Degree',
                            prefixIcon: Icon(Icons.menu_book_outlined),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _eduYearController,
                          decoration: const InputDecoration(
                            labelText: 'Year',
                            prefixIcon: Icon(Icons.calendar_today_outlined),
                          ),
                        ),
                      ],
                    )
                  : profile.education.isEmpty
                      ? const Text('No education entries yet')
                      : Column(
                          children: profile.education
                              .map(
                                (e) => _TimelineTile(
                                  title: e.degree,
                                  subtitle: '${e.institution} · ${e.year}',
                                  icon: Icons.school_outlined,
                                ),
                              )
                              .toList(),
                        ),
              const SizedBox(height: 24),
              _sectionTitle(context, 'Experience'),
              _isEditing
                  ? Column(
                      children: [
                        TextFormField(
                          controller: _expCompanyController,
                          decoration: const InputDecoration(
                            labelText: 'Company',
                            prefixIcon: Icon(Icons.business_outlined),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _expRoleController,
                          decoration: const InputDecoration(
                            labelText: 'Role',
                            prefixIcon: Icon(Icons.work_outline),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _expDurationController,
                          decoration: const InputDecoration(
                            labelText: 'Duration',
                            prefixIcon: Icon(Icons.date_range_outlined),
                          ),
                        ),
                      ],
                    )
                  : profile.experience.isEmpty
                      ? const Text('No experience entries yet')
                      : Column(
                          children: profile.experience
                              .map(
                                (e) => _TimelineTile(
                                  title: e.role,
                                  subtitle: '${e.company} · ${e.duration}',
                                  icon: Icons.work_outline,
                                ),
                              )
                              .toList(),
                        ),
              if (profile.cvUrl != null) ...[
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.description_outlined),
                  title: const Text('Resume on file'),
                  subtitle: Text(
                    profile.cvUrl!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  contentPadding: EdgeInsets.zero,
                ),
              ],
              if (_isEditing) ...[
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _uploading ? null : _uploadCv,
                  icon: _uploading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.upload_file),
                  label: Text(UserConstants.cvUploadLabel),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _sectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.profile,
    required this.isEditing,
    required this.onPhotoUploaded,
  });

  final UserProfile profile;
  final bool isEditing;
  final Future<void> Function(String url) onPhotoUploaded;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            isEditing
                ? ProfileAvatarPicker(
                    photoUrl: profile.photoUrl,
                    displayName: profile.displayName,
                    onUploaded: onPhotoUploaded,
                  )
                : CircleAvatar(
                    radius: 48,
                    backgroundColor: context.colorScheme.primaryContainer,
                    backgroundImage: profile.photoUrl != null
                        ? NetworkImage(profile.photoUrl!)
                        : null,
                    child: profile.photoUrl == null
                        ? Text(
                            profile.displayName[0].toUpperCase(),
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: context.colorScheme.primary,
                            ),
                          )
                        : null,
                  ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile.displayName,
                    style: context.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(profile.email),
                  if (profile.phone != null)
                    Text('📱 ${profile.phone}', style: context.textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimelineTile extends StatelessWidget {
  const _TimelineTile({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: context.colorScheme.primary),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle),
      contentPadding: EdgeInsets.zero,
    );
  }
}
