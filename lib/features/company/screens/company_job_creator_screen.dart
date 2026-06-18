import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/l10n/locale_provider.dart';
import '../../../core/services/toast_service.dart';
import '../../../core/utils/extensions.dart';
import '../../../core/widgets/media_permission_helper.dart';
import '../../../core/widgets/rozgar_shell_body.dart';
import '../../auth/provider/auth_provider.dart';
import '../constants/company_constants.dart';
import '../provider/company_job_creator_provider.dart';

class CompanyJobCreatorScreen extends ConsumerStatefulWidget {
  const CompanyJobCreatorScreen({super.key});

  @override
  ConsumerState<CompanyJobCreatorScreen> createState() =>
      _CompanyJobCreatorScreenState();
}

class _CompanyJobCreatorScreenState
    extends ConsumerState<CompanyJobCreatorScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _salaryController = TextEditingController();
  final _tagsController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _salaryController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _pickBannerSource() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Text(
              'Job Banner',
              style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'Camera or gallery',
              style: Theme.of(ctx).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Take Photo'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from Gallery'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;

    final allowed = await MediaPermissionHelper.ensureAccess(
      context,
      ref,
      source: source,
    );
    if (!allowed || !mounted) return;

    final result = await ref
        .read(jobCreatorProvider.notifier)
        .pickAndUploadBanner(source, skipPermissionCheck: true);
    if (!mounted) return;
    result.when(
      success: (_) =>
          ToastService.success(context, 'Banner uploaded to Cloudinary'),
      failure: (msg, _) => ToastService.error(context, msg),
    );
  }

  bool _validateAllFields() {
    if (_titleController.text.trim().isEmpty) {
      ToastService.error(context, 'Job title is required');
      return false;
    }
    if (_descriptionController.text.trim().isEmpty) {
      ToastService.error(context, 'Job description is required');
      return false;
    }
    if (_locationController.text.trim().isEmpty) {
      ToastService.error(context, 'Location is required');
      return false;
    }
    return true;
  }

  void _handleNext() {
    final notifier = ref.read(jobCreatorProvider.notifier);
    final creator = ref.read(jobCreatorProvider);

    if (creator.currentStep == 0) {
      if (!notifier.step1Key.currentState!.validate()) return;
      notifier.nextStep();
    } else if (creator.currentStep == 1) {
      if (!notifier.step2Key.currentState!.validate()) return;
      notifier.nextStep();
    } else {
      _publish();
    }
  }

  Future<void> _publish() async {
    final notifier = ref.read(jobCreatorProvider.notifier);
    final user = ref.read(authNotifierProvider).value;
    if (user == null) return;

    if (!_validateAllFields()) return;

    final creator = ref.read(jobCreatorProvider);
    if (creator.bannerUrl == null) {
      ToastService.error(context, 'Please upload a job banner thumbnail');
      return;
    }

    final result = await notifier.publishJob(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      location: _locationController.text.trim(),
      salary: _salaryController.text.trim(),
      companyId: user.uid,
      companyName: user.displayName ?? 'Company',
      tags: _tagsController.text
          .split(',')
          .map((t) => t.trim())
          .where((t) => t.isNotEmpty)
          .toList(),
    );

    if (!mounted) return;
    result.when(
      success: (_) {
        _titleController.clear();
        _descriptionController.clear();
        _locationController.clear();
        _salaryController.clear();
        _tagsController.clear();
        ToastService.success(context, 'Job published successfully!');
      },
      failure: (msg, _) => ToastService.error(context, msg),
    );
  }

  @override
  Widget build(BuildContext context) {
    final creator = ref.watch(jobCreatorProvider);
    final notifier = ref.read(jobCreatorProvider.notifier);
    final s = ref.watch(stringsProvider);

    return RozgarShellBody(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.postAJob,
                  style: context.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  s.stepProgress(
                    creator.currentStep + 1,
                    _stepSubtitle(creator.currentStep, s),
                  ),
                  style: context.textTheme.bodySmall?.copyWith(
                    color: context.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          _StepIndicator(current: creator.currentStep, strings: s),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              child: switch (creator.currentStep) {
                0 => _Step1Form(
                    key: const ValueKey(0),
                    formKey: notifier.step1Key,
                    titleController: _titleController,
                    descriptionController: _descriptionController,
                  ),
                1 => _Step2Form(
                    key: const ValueKey(1),
                    formKey: notifier.step2Key,
                    locationController: _locationController,
                    salaryController: _salaryController,
                    tagsController: _tagsController,
                  ),
                _ => _Step3Banner(
                    key: ValueKey(creator.bannerUrl ?? 'empty'),
                    bannerUrl: creator.bannerUrl,
                    isUploading: creator.isUploading,
                    onUpload: _pickBannerSource,
                  ),
              },
            ),
          ),
          SafeArea(
            top: false,
            child: _NavigationBar(
              currentStep: creator.currentStep,
              isPosting: creator.isPosting,
              onBack: notifier.previousStep,
              onNext: _handleNext,
              isLastStep: creator.currentStep == 2,
              strings: s,
            ),
          ),
        ],
      ),
    );
  }

  String _stepSubtitle(int step, AppStrings s) => switch (step) {
        0 => s.stepDetails,
        1 => s.stepCompensation,
        _ => s.stepBanner,
      };
}

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.current, required this.strings});
  final int current;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final labels = [strings.stepDetailsShort, strings.stepPayShort, strings.stepBannerShort];
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Row(
        children: List.generate(labels.length, (i) {
          final isActive = i <= current;
          final isCurrent = i == current;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: i < labels.length - 1 ? 8 : 0),
              child: Column(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: 4,
                    decoration: BoxDecoration(
                      color: isActive
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    labels[i],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
                      color: isCurrent
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _Step1Form extends StatelessWidget {
  const _Step1Form({
    super.key,
    required this.formKey,
    required this.titleController,
    required this.descriptionController,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController titleController;
  final TextEditingController descriptionController;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: formKey,
        child: Column(
          children: [
            TextFormField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Job Title',
                prefixIcon: Icon(Icons.title),
              ),
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Job Description',
                prefixIcon: Icon(Icons.description_outlined),
              ),
              maxLines: 6,
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _Step2Form extends StatelessWidget {
  const _Step2Form({
    super.key,
    required this.formKey,
    required this.locationController,
    required this.salaryController,
    required this.tagsController,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController locationController;
  final TextEditingController salaryController;
  final TextEditingController tagsController;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: formKey,
        child: Column(
          children: [
            TextFormField(
              controller: locationController,
              decoration: const InputDecoration(
                labelText: 'Location',
                prefixIcon: Icon(Icons.location_on_outlined),
              ),
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: salaryController,
              decoration: const InputDecoration(
                labelText: 'Salary Range',
                prefixIcon: Icon(Icons.payments_outlined),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: tagsController,
              decoration: const InputDecoration(
                labelText: 'Tags (comma separated)',
                prefixIcon: Icon(Icons.label_outline),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Step3Banner extends StatelessWidget {
  const _Step3Banner({
    super.key,
    required this.bannerUrl,
    required this.isUploading,
    required this.onUpload,
  });

  final String? bannerUrl;
  final bool isUploading;
  final VoidCallback onUpload;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
        children: [
          Text(
            'Upload Job Banner',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Camera or gallery — uploaded to Cloudinary CDN',
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            child: isUploading
                ? Container(
                    key: const ValueKey('loading'),
                    height: 160,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 12),
                        Text('Uploading banner...'),
                      ],
                    ),
                  )
                : bannerUrl != null
                    ? ClipRRect(
                        key: ValueKey(bannerUrl),
                        borderRadius: BorderRadius.circular(16),
                        child: CachedNetworkImage(
                          imageUrl: bannerUrl!,
                          height: 160,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Container(
                        key: const ValueKey('placeholder'),
                        height: 160,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Icon(
                          Icons.image_outlined,
                          size: 48,
                          color: Colors.grey.shade400,
                        ),
                      ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: isUploading ? null : onUpload,
              icon: const Icon(Icons.cloud_upload_outlined),
              label: Text(
                bannerUrl != null ? 'Change Banner' : 'Upload Banner',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavigationBar extends StatelessWidget {
  const _NavigationBar({
    required this.currentStep,
    required this.isPosting,
    required this.onBack,
    required this.onNext,
    required this.isLastStep,
    required this.strings,
  });

  final int currentStep;
  final bool isPosting;
  final VoidCallback onBack;
  final VoidCallback onNext;
  final bool isLastStep;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          if (currentStep > 0)
            OutlinedButton(onPressed: onBack, child: Text(strings.back)),
          const Spacer(),
          ElevatedButton(
            onPressed: isPosting ? null : onNext,
            child: isPosting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(isLastStep ? strings.publishJob : strings.continueBtn),
          ),
        ],
      ),
    );
  }
}
