import 'package:permission_handler/permission_handler.dart';

import '../utils/app_logger.dart';
import '../utils/result.dart';

class PermissionService {
  Future<Result<bool>> requestCamera() => _request(Permission.camera, 'Camera');

  Future<Result<bool>> requestStorage() =>
      _request(Permission.storage, 'Storage');

  Future<Result<bool>> requestPhotos() => _request(Permission.photos, 'Photos');

  Future<Result<bool>> requestMediaForUpload() async {
    final camera = await requestCamera();
    if (camera.isFailure) return camera;

    final storage = await requestStorage();
    if (storage.isSuccess && storage.dataOrNull == true) return storage;

    return requestPhotos();
  }

  Future<Result<bool>> _request(
    Permission permission,
    String label,
  ) async {
    final status = await permission.status;
    if (status.isGranted) return const Success(true);

    if (status.isPermanentlyDenied) {
      AppLogger.warning('$label permission permanently denied');
      return Failure('$label permission permanently denied. Open settings.');
    }

    final result = await permission.request();
    if (result.isGranted) return const Success(true);
    return Failure('$label permission denied');
  }

  Future<void> openSettings() => openAppSettings();
}
