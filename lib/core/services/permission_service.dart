import 'dart:io';

import 'package:permission_handler/permission_handler.dart';

import '../utils/app_logger.dart';
import '../utils/result.dart';

class PermissionService {
  Future<Result<bool>> requestCamera() => _request(Permission.camera, 'Camera');

  Future<Result<bool>> requestStorage() =>
      _request(Permission.storage, 'Storage');

  Future<Result<bool>> requestPhotos() => _request(Permission.photos, 'Photos');

  Future<Result<bool>> requestNotifications() async {
    if (Platform.isAndroid || Platform.isIOS) {
      return _request(Permission.notification, 'Notifications');
    }
    return const Success(true);
  }

  Future<Result<bool>> requestGallery() async {
    final photos = await requestPhotos();
    if (photos.isSuccess && photos.dataOrNull == true) return photos;

    final storage = await requestStorage();
    if (storage.isSuccess && storage.dataOrNull == true) return storage;

    return photos.isFailure ? photos : storage;
  }

  /// Gallery/file pickers (banner, resume, profile from library).
  Future<Result<bool>> requestMediaForUpload() async {
    final gallery = await requestGallery();
    if (gallery.isSuccess) return gallery;
    return Failure(
      gallery.when(
        success: (_) => '',
        failure: (m, _) => m,
      ),
    );
  }

  /// Camera capture flow.
  Future<Result<bool>> requestCameraAccess() async {
    final camera = await requestCamera();
    if (camera.isSuccess) return camera;
    return Failure(
      camera.when(
        success: (_) => '',
        failure: (m, _) => m,
      ),
    );
  }

  /// Request all permissions needed at app start.
  Future<void> requestEssentialPermissions() async {
    await requestNotifications();
    AppLogger.info('Essential permissions requested');
  }

  Future<Result<bool>> _request(
    Permission permission,
    String label,
  ) async {
    final status = await permission.status;
    if (status.isGranted || status.isLimited) return const Success(true);

    if (status.isPermanentlyDenied) {
      AppLogger.warning('$label permission permanently denied');
      return Failure('$label permission permanently denied. Open Settings.');
    }

    final result = await permission.request();
    if (result.isGranted || result.isLimited) {
      AppLogger.info('$label permission granted');
      return const Success(true);
    }

    if (result.isPermanentlyDenied) {
      return Failure('$label permission permanently denied. Open Settings.');
    }

    AppLogger.warning('$label permission denied');
    return Failure(
      '$label permission denied. Tap Continue on the next prompt to allow access.',
    );
  }

  Future<void> openSettings() => openAppSettings();
}
