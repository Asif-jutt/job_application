import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../constants/cloudinary_constants.dart';
import '../utils/app_logger.dart';
import '../utils/result.dart';
import 'performance_service.dart';

enum CloudinaryUploadType { image, document, jobBanner, resume, profile }

/// Unified multipart Cloudinary upload pipeline for all Rozgar media assets.
class CloudinaryService {
  CloudinaryService({
    Dio? dio,
    PerformanceService? performanceService,
  })  : _dio = dio ?? Dio(),
        _performance = performanceService ?? PerformanceService();

  final Dio _dio;
  final PerformanceService _performance;

  Future<Result<String>> uploadFile(
    File file, {
    CloudinaryUploadType type = CloudinaryUploadType.image,
    String? folder,
  }) async {
    final traceName = switch (type) {
      CloudinaryUploadType.jobBanner => 'cloudinary_upload_job_banner',
      CloudinaryUploadType.resume => 'cloudinary_upload_resume',
      CloudinaryUploadType.profile => 'cloudinary_upload_profile',
      CloudinaryUploadType.document => 'cloudinary_upload_document',
      CloudinaryUploadType.image => 'cloudinary_upload_image',
    };

    return _performance.trace(traceName, () async {
      try {
        final endpoint = type == CloudinaryUploadType.document ||
                type == CloudinaryUploadType.resume
            ? CloudinaryConstants.rawUploadUrl
            : CloudinaryConstants.uploadUrl;

        final formData = FormData.fromMap({
          'file': await MultipartFile.fromFile(
            file.path,
            filename: file.path.split(Platform.pathSeparator).last,
          ),
          'upload_preset': CloudinaryConstants.unsignedUploadPreset,
          'api_key': CloudinaryConstants.apiKey,
          if (folder != null) 'folder': folder,
        });

        AppLogger.network('Cloudinary', 'POST $endpoint [${type.name}]');

        final response = await _dio.post<Map<String, dynamic>>(
          endpoint,
          data: formData,
          options: Options(
            sendTimeout: const Duration(seconds: 60),
            receiveTimeout: const Duration(seconds: 60),
          ),
        );

        final secureUrl = response.data?['secure_url'] as String?;
        if (secureUrl == null || secureUrl.isEmpty) {
          return const Failure<String>('Upload failed: no secure_url returned');
        }

        AppLogger.info('Cloudinary upload success: $secureUrl');
        return Success(secureUrl);
      } catch (e, st) {
        AppLogger.severe('Cloudinary upload failed [${type.name}]', e, st);
        return Failure('Failed to upload ${type.name}', e);
      }
    });
  }

  Future<Result<String>> uploadJobBanner(File file) => uploadFile(
        file,
        type: CloudinaryUploadType.jobBanner,
        folder: CloudinaryConstants.jobBannerFolder,
      );

  Future<Result<String>> uploadResume(File file) => uploadFile(
        file,
        type: CloudinaryUploadType.resume,
        folder: CloudinaryConstants.resumeFolder,
      );

  Future<Result<String>> uploadProfileImage(File file) => uploadFile(
        file,
        type: CloudinaryUploadType.profile,
        folder: CloudinaryConstants.profileFolder,
      );

  Future<Result<String>> uploadFromXFile(
    XFile xFile, {
    CloudinaryUploadType type = CloudinaryUploadType.image,
    String? folder,
  }) async {
    if (kIsWeb) {
      return _uploadBytes(
        await xFile.readAsBytes(),
        xFile.name,
        type: type,
        folder: folder,
      );
    }
    return uploadFile(File(xFile.path), type: type, folder: folder);
  }

  Future<Result<String>> _uploadBytes(
    Uint8List bytes,
    String filename, {
    required CloudinaryUploadType type,
    String? folder,
  }) async {
    try {
      final endpoint = type == CloudinaryUploadType.document ||
              type == CloudinaryUploadType.resume
          ? CloudinaryConstants.rawUploadUrl
          : CloudinaryConstants.uploadUrl;

      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(bytes, filename: filename),
        'upload_preset': CloudinaryConstants.unsignedUploadPreset,
        'api_key': CloudinaryConstants.apiKey,
        if (folder != null) 'folder': folder,
      });

      final response = await _dio.post<Map<String, dynamic>>(
        endpoint,
        data: formData,
      );

      final secureUrl = response.data?['secure_url'] as String?;
      if (secureUrl == null) {
        return const Failure<String>('Upload failed: no secure_url returned');
      }
      return Success(secureUrl);
    } catch (e, st) {
      AppLogger.severe('Cloudinary web upload failed', e, st);
      return Failure('Failed to upload file', e);
    }
  }
}
