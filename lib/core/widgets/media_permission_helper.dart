import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../providers/core_providers.dart';
import '../services/toast_service.dart';
import '../utils/extensions.dart';

/// Shows rationale → system permission dialog → settings fallback.
class MediaPermissionHelper {
  MediaPermissionHelper._();

  static Future<bool> ensureAccess(
    BuildContext context,
    WidgetRef ref, {
    required ImageSource source,
  }) async {
    final permission = source == ImageSource.camera
        ? Permission.camera
        : await _galleryPermission();

    final status = await permission.status;
    if (status.isGranted || status.isLimited) return true;

    if (status.isPermanentlyDenied) {
      if (context.mounted) await _showSettingsDialog(context, source);
      return false;
    }

    if (status.isDenied) {
      if (!context.mounted) return false;
      final proceed = await _showRationaleDialog(context, source);
      if (!proceed) return false;
    }

    final service = ref.read(permissionServiceProvider);
    final result = source == ImageSource.camera
        ? await service.requestCameraAccess()
        : await service.requestMediaForUpload();

    if (result.isSuccess && result.dataOrNull == true) return true;

    final message = result.when(
      success: (_) => 'Permission denied',
      failure: (m, _) => m,
    );

    if (!context.mounted) return false;
    final permStatus = await permission.status;
    if (permStatus.isPermanentlyDenied) {
      await _showSettingsDialog(context, source);
    } else {
      ToastService.error(context, message);
    }
    return false;
  }

  static Future<Permission> _galleryPermission() async {
    if (!kIsWeb && Platform.isAndroid) {
      return Permission.photos;
    }
    return Permission.photos;
  }

  static Future<bool> _showRationaleDialog(
    BuildContext context,
    ImageSource source,
  ) async {
    final isCamera = source == ImageSource.camera;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(
          isCamera ? Icons.camera_alt_outlined : Icons.photo_library_outlined,
          color: ctx.colorScheme.primary,
        ),
        title: Text(isCamera ? 'Camera Access' : 'Photo Library Access'),
        content: Text(
          isCamera
              ? 'Rozgar needs camera access so you can take profile photos, job banners, and resume images.'
              : 'Rozgar needs photo library access so you can upload images from your gallery.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Not Now'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  static Future<void> _showSettingsDialog(
    BuildContext context,
    ImageSource source,
  ) async {
    final isCamera = source == ImageSource.camera;
    final open = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Permission Required'),
        content: Text(
          isCamera
              ? 'Camera access was denied. Open Settings to allow Rozgar to use your camera.'
              : 'Photo access was denied. Open Settings to allow Rozgar to access your gallery.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
    if (open == true) await openAppSettings();
  }
}
