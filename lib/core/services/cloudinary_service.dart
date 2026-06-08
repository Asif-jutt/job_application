import 'dart:io';

import 'package:dio/dio.dart';

import '../constants/cloudinary_constants.dart';
import '../utils/app_logger.dart';
import '../utils/result.dart';
import 'performance_service.dart';

class CloudinaryService {
  CloudinaryService({
    Dio? dio,
    PerformanceService? performanceService,
  })  : _dio = dio ?? Dio(),
        _performance = performanceService ?? PerformanceService();

  final Dio _dio;
  final PerformanceService _performance;

  Future<Result<String>> uploadImage(
    File file, {
    bool signed = false,
  }) async {
    return _performance.trace('cloudinary_upload_image', () async {
      try {
        final preset = signed
            ? CloudinaryConstants.signedUploadPreset
            : CloudinaryConstants.unsignedUploadPreset;

        final formData = FormData.fromMap({
          'file': await MultipartFile.fromFile(file.path),
          'upload_preset': preset,
          'api_key': CloudinaryConstants.apiKey,
        });

        AppLogger.network('Cloudinary', 'Uploading to ${CloudinaryConstants.uploadUrl}');

        final response = await _dio.post(
          CloudinaryConstants.uploadUrl,
          data: formData,
        );

        final secureUrl = response.data['secure_url'] as String?;
        if (secureUrl == null) {
          return const Failure<String>('Upload failed: no URL returned');
        }
        return Success(secureUrl);
      } catch (e, st) {
        AppLogger.severe('Cloudinary upload failed', e, st);
        return Failure('Failed to upload image', e);
      }
    });
  }

  Future<Result<String>> uploadDocument(File file) async {
    return _performance.trace('cloudinary_upload_document', () async {
      try {
        final formData = FormData.fromMap({
          'file': await MultipartFile.fromFile(file.path),
          'upload_preset': CloudinaryConstants.unsignedUploadPreset,
          'api_key': CloudinaryConstants.apiKey,
        });

        final response = await _dio.post(
          CloudinaryConstants.rawUploadUrl,
          data: formData,
        );

        final secureUrl = response.data['secure_url'] as String?;
        if (secureUrl == null) {
          return const Failure<String>('Upload failed: no URL returned');
        }
        return Success(secureUrl);
      } catch (e, st) {
        AppLogger.severe('Cloudinary document upload failed', e, st);
        return Failure('Failed to upload document', e);
      }
    });
  }
}
