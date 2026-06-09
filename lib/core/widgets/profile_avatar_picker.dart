import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../providers/core_providers.dart';
import '../services/cloudinary_service.dart';
import '../services/toast_service.dart';
import '../utils/extensions.dart';
import 'media_permission_helper.dart';

/// Reusable avatar with camera/gallery picker and Cloudinary upload.
class ProfileAvatarPicker extends ConsumerStatefulWidget {
  const ProfileAvatarPicker({
    super.key,
    required this.photoUrl,
    required this.displayName,
    required this.onUploaded,
    this.radius = 48,
  });

  final String? photoUrl;
  final String displayName;
  final Future<void> Function(String url) onUploaded;
  final double radius;

  @override
  ConsumerState<ProfileAvatarPicker> createState() =>
      _ProfileAvatarPickerState();
}

class _ProfileAvatarPickerState extends ConsumerState<ProfileAvatarPicker> {
  bool _uploading = false;

  Future<void> _pick(ImageSource source) async {
    final allowed = await MediaPermissionHelper.ensureAccess(
      context,
      ref,
      source: source,
    );
    if (!allowed) return;

    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: source,
      maxWidth: 1024,
      imageQuality: 85,
    );
    if (file == null) return;

    setState(() => _uploading = true);
    final upload = await ref.read(cloudinaryServiceProvider).uploadFromXFile(
          file,
          type: CloudinaryUploadType.profile,
        );
    setState(() => _uploading = false);

    if (!mounted) return;
    if (upload.isFailure) {
      upload.when(
        success: (_) {},
        failure: (msg, _) => ToastService.error(context, msg),
      );
      return;
    }

    final url = upload.when(success: (v) => v, failure: (_, _) => '');
    await widget.onUploaded(url);
    if (mounted) ToastService.success(context, 'Profile photo updated');
  }

  void _showSourceSheet() {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(ctx);
                _pick(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(ctx);
                _pick(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CircleAvatar(
          radius: widget.radius,
          backgroundColor: context.colorScheme.primaryContainer,
          backgroundImage: widget.photoUrl != null
              ? CachedNetworkImageProvider(widget.photoUrl!)
              : null,
          child: widget.photoUrl == null
              ? _uploading
                  ? const CircularProgressIndicator(strokeWidth: 2)
                  : Text(
                      widget.displayName.isNotEmpty
                          ? widget.displayName[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        fontSize: widget.radius * 0.7,
                        fontWeight: FontWeight.bold,
                        color: context.colorScheme.primary,
                      ),
                    )
              : _uploading
                  ? const CircularProgressIndicator(strokeWidth: 2)
                  : null,
        ),
        Positioned(
          right: 0,
          bottom: 0,
          child: Material(
            color: context.colorScheme.primary,
            shape: const CircleBorder(),
            child: InkWell(
              onTap: _uploading ? null : _showSourceSheet,
              customBorder: const CircleBorder(),
              child: const Padding(
                padding: EdgeInsets.all(6),
                child: Icon(Icons.camera_alt, color: Colors.white, size: 18),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
