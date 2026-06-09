import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/models/job_model.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/services/cloudinary_service.dart';
import '../../../core/utils/app_logger.dart';
import '../../../core/utils/result.dart';

class JobCreatorState {
  const JobCreatorState({
    this.currentStep = 0,
    this.isUploading = false,
    this.isPosting = false,
    this.bannerUrl,
    this.bannerFile,
  });

  final int currentStep;
  final bool isUploading;
  final bool isPosting;
  final String? bannerUrl;
  final File? bannerFile;

  JobCreatorState copyWith({
    int? currentStep,
    bool? isUploading,
    bool? isPosting,
    String? bannerUrl,
    File? bannerFile,
  }) =>
      JobCreatorState(
        currentStep: currentStep ?? this.currentStep,
        isUploading: isUploading ?? this.isUploading,
        isPosting: isPosting ?? this.isPosting,
        bannerUrl: bannerUrl ?? this.bannerUrl,
        bannerFile: bannerFile ?? this.bannerFile,
      );
}

class JobCreatorNotifier extends StateNotifier<JobCreatorState> {
  JobCreatorNotifier(this._ref) : super(const JobCreatorState());

  final Ref _ref;

  final step1Key = GlobalKey<FormState>();
  final step2Key = GlobalKey<FormState>();
  final step3Key = GlobalKey<FormState>();

  void nextStep() {
    if (state.currentStep < 2) {
      state = state.copyWith(currentStep: state.currentStep + 1);
    }
  }

  void previousStep() {
    if (state.currentStep > 0) {
      state = state.copyWith(currentStep: state.currentStep - 1);
    }
  }

  Future<Result<String>> pickAndUploadBanner(
    ImageSource source, {
    bool skipPermissionCheck = false,
  }) async {
    if (!skipPermissionCheck) {
      final permission = _ref.read(permissionServiceProvider);
      final permResult = source == ImageSource.camera
          ? await permission.requestCameraAccess()
          : await permission.requestMediaForUpload();
      if (permResult.isFailure) {
        return Failure(permResult.when(
          success: (_) => '',
          failure: (m, _) => m,
        ));
      }
    }

    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: source,
      maxWidth: 1920,
      imageQuality: 85,
    );
    if (file == null) return const Failure('No image selected');

    state = state.copyWith(isUploading: true, bannerUrl: null);
    final upload = await _ref.read(cloudinaryServiceProvider).uploadFromXFile(
          file,
          type: CloudinaryUploadType.jobBanner,
        );
    state = state.copyWith(isUploading: false);

    return upload.when(
      success: (url) {
        state = state.copyWith(
          bannerUrl: url,
          bannerFile: kIsWeb ? null : File(file.path),
        );
        return Success(url);
      },
      failure: (msg, _) => Failure(msg),
    );
  }

  Future<Result<void>> publishJob({
    required String title,
    required String description,
    required String location,
    required String salary,
    required String companyId,
    required String companyName,
    List<String> tags = const [],
  }) async {
    state = state.copyWith(isPosting: true);
    try {
      final job = JobModel(
        id: '',
        title: title,
        company: companyName,
        description: description,
        location: location,
        salary: salary.isNotEmpty ? salary : null,
        isPremium: true,
        source: JobSource.firestore,
        postedAt: DateTime.now(),
        companyId: companyId,
        tags: tags,
        bannerUrl: state.bannerUrl,
      );

      final data = job.toFirestore();
      data['postedAt'] = FieldValue.serverTimestamp();

      await _ref.read(firestoreServiceProvider).addJob(data);
      AppLogger.info('Premium job posted with banner: ${state.bannerUrl}');

      state = const JobCreatorState();
      return const Success(null);
    } catch (e, st) {
      AppLogger.severe('Job publish failed', e, st);
      state = state.copyWith(isPosting: false);
      return Failure('Failed to publish job: $e', e);
    }
  }
}

final jobCreatorProvider =
    StateNotifierProvider<JobCreatorNotifier, JobCreatorState>((ref) {
  return JobCreatorNotifier(ref);
});
