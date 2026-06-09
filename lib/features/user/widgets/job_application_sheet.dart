import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/models/job_model.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/services/cloudinary_service.dart';
import '../../../core/services/toast_service.dart';
import '../../../core/widgets/media_permission_helper.dart';
import '../../auth/provider/auth_provider.dart';
import '../provider/application_provider.dart';

Future<void> showJobApplicationSheet(
  BuildContext context,
  WidgetRef ref,
  JobModel job,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return _JobApplicationSheet(job: job, scrollController: scrollController);
      },
    ),
  );
}

class _JobApplicationSheet extends ConsumerStatefulWidget {
  const _JobApplicationSheet({
    required this.job,
    required this.scrollController,
  });

  final JobModel job;
  final ScrollController scrollController;

  @override
  ConsumerState<_JobApplicationSheet> createState() =>
      _JobApplicationSheetState();
}

class _JobApplicationSheetState extends ConsumerState<_JobApplicationSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _experienceController = TextEditingController();
  String? _resumeUrl;
  bool _isSubmitting = false;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authNotifierProvider).value;
    _nameController.text = user?.displayName ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _experienceController.dispose();
    super.dispose();
  }

  Future<void> _pickResume() async {
    final allowed = await MediaPermissionHelper.ensureAccess(
      context,
      ref,
      source: ImageSource.gallery,
    );
    if (!allowed) return;

    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;

    setState(() => _isUploading = true);
    final upload = await ref.read(cloudinaryServiceProvider).uploadFromXFile(
          file,
          type: CloudinaryUploadType.resume,
        );
    setState(() => _isUploading = false);

    if (!mounted) return;
    upload.when(
      success: (url) {
        setState(() => _resumeUrl = url);
        ToastService.success(context, 'Resume uploaded successfully');
      },
      failure: (msg, _) => ToastService.error(context, msg),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final user = ref.read(authNotifierProvider).value;
    if (user == null) return;

    setState(() => _isSubmitting = true);

    final result = await ref.read(applicationRepositoryProvider).submitApplication(
          job: widget.job,
          applicantId: user.uid,
          applicantName: _nameController.text.trim(),
          experience: _experienceController.text.trim(),
          resumeUrl: _resumeUrl,
        );

    setState(() => _isSubmitting = false);
    if (!mounted) return;

    result.when(
      success: (_) {
        Navigator.pop(context);
        ToastService.success(
          context,
          'Application submitted for ${widget.job.title}!',
        );
      },
      failure: (msg, _) => ToastService.error(context, msg),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: ListView(
        controller: widget.scrollController,
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Apply to ${widget.job.title}',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          Text(widget.job.company, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 24),
          Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Name is required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _experienceController,
                  decoration: const InputDecoration(
                    labelText: 'Years of Experience',
                    prefixIcon: Icon(Icons.work_history_outlined),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Experience is required' : null,
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _isUploading ? null : _pickResume,
                  icon: _isUploading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.upload_file),
                  label: Text(
                    _resumeUrl != null ? 'Resume Uploaded ✓' : 'Upload Resume',
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submit,
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Submit Application'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
