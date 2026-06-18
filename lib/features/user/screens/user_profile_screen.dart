import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/providers/core_providers.dart';
import '../../../core/services/cloudinary_service.dart';
import '../../../core/services/toast_service.dart';
import '../../../core/utils/extensions.dart';
import '../../../core/widgets/profile_avatar_picker.dart';
import '../../../core/widgets/profile_page_layout.dart';
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

  List<Widget> _editActions(UserProfile profile) {
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
        onPressed: _saving ? null : _saveProfile,
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

        return ProfilePageLayout(
          title: 'My Profile',
          actions: _editActions(profile),
          header: ProfileHeroCard(
            avatar: _isEditing
                ? ProfileAvatarPicker(
                    photoUrl: profile.photoUrl,
                    displayName: profile.displayName,
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
            name: profile.displayName,
            subtitle: profile.email,
            badge: profile.phone != null
                ? Chip(
                    avatar: const Icon(Icons.phone, size: 16),
                    label: Text(profile.phone!),
                    visualDensity: VisualDensity.compact,
                  )
                : null,
          ),
          body: Column(
            children: [
              ProfileSectionCard(
                title: 'About',
                icon: Icons.info_outline,
                child: _isEditing
                    ? TextFormField(
                        controller: _headlineController,
                        decoration: const InputDecoration(
                          hintText: 'Professional headline',
                          border: OutlineInputBorder(),
                        ),
                      )
                    : Text(profile.headline ?? 'No headline yet'),
              ),
              const SizedBox(height: 12),
              ProfileSectionCard(
                title: UserConstants.salaryLabel,
                icon: Icons.payments_outlined,
                child: _isEditing
                    ? TextFormField(
                        controller: _salaryController,
                        decoration: const InputDecoration(
                          hintText: 'Expected compensation (encrypted)',
                          helperText:
                              'AES-256 CTR encrypted before Firestore write',
                          border: OutlineInputBorder(),
                        ),
                      )
                    : Text(
                        profile.salary?.isNotEmpty == true
                            ? profile.salary!
                            : 'Not specified',
                      ),
              ),
              const SizedBox(height: 12),
              ProfileSectionCard(
                title: 'Skills',
                icon: Icons.star_outline,
                child: _isEditing
                    ? TextFormField(
                        controller: _skillsController,
                        decoration: const InputDecoration(
                          hintText: 'Flutter, Firebase, Dart (comma separated)',
                          border: OutlineInputBorder(),
                        ),
                      )
                    : profile.skills.isEmpty
                        ? const Text('No skills added yet')
                        : Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: profile.skills
                                .map(
                                  (s) => Chip(
                                    label: Text(s),
                                    backgroundColor:
                                        context.colorScheme.primaryContainer,
                                  ),
                                )
                                .toList(),
                          ),
              ),
              const SizedBox(height: 12),
              ProfileSectionCard(
                title: 'Education',
                icon: Icons.school_outlined,
                child: _isEditing
                    ? Column(
                        children: [
                          TextFormField(
                            controller: _eduInstitutionController,
                            decoration: const InputDecoration(
                              labelText: 'Institution',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _eduDegreeController,
                            decoration: const InputDecoration(
                              labelText: 'Degree',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _eduYearController,
                            decoration: const InputDecoration(
                              labelText: 'Year',
                              border: OutlineInputBorder(),
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
              ),
              const SizedBox(height: 12),
              ProfileSectionCard(
                title: 'Experience',
                icon: Icons.work_outline,
                child: _isEditing
                    ? Column(
                        children: [
                          TextFormField(
                            controller: _expCompanyController,
                            decoration: const InputDecoration(
                              labelText: 'Company',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _expRoleController,
                            decoration: const InputDecoration(
                              labelText: 'Role',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _expDurationController,
                            decoration: const InputDecoration(
                              labelText: 'Duration',
                              border: OutlineInputBorder(),
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
              ),
              if (profile.cvUrl != null) ...[
                const SizedBox(height: 12),
                ProfileSectionCard(
                  title: 'Resume',
                  icon: Icons.description_outlined,
                  child: Text(
                    profile.cvUrl!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: context.textTheme.bodySmall,
                  ),
                ),
              ],
              if (_isEditing) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
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
                ),
              ],
            ],
          ),
        );
      },
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
