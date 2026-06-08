import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/providers/core_providers.dart';
import '../../../core/utils/extensions.dart';
import '../../auth/provider/auth_provider.dart';
import '../constants/user_constants.dart';

class UserProfileScreen extends ConsumerStatefulWidget {
  const UserProfileScreen({super.key});

  @override
  ConsumerState<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends ConsumerState<UserProfileScreen> {
  final _salaryController = TextEditingController();
  bool _uploading = false;

  @override
  void dispose() {
    _salaryController.dispose();
    super.dispose();
  }

  Future<void> _uploadCv() async {
    final permission = ref.read(permissionServiceProvider);
    final result = await permission.requestMediaForUpload();
    if (result.isFailure) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.when(
            success: (_) => '',
            failure: (msg, _) => msg,
          ))),
        );
      }
      return;
    }

    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;

    setState(() => _uploading = true);
    final cloudinary = ref.read(cloudinaryServiceProvider);
    final uploadResult = await cloudinary.uploadDocument(File(file.path));
    setState(() => _uploading = false);

    if (!mounted) return;
    uploadResult.when(
      success: (url) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('CV uploaded successfully')),
        );
      },
      failure: (msg, _) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authNotifierProvider).value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authNotifierProvider.notifier).signOut(),
          ),
        ],
      ),
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 48,
                    backgroundColor: context.colorScheme.primaryContainer,
                    child: Text(
                      (user.displayName ?? user.email)[0].toUpperCase(),
                      style: TextStyle(
                        fontSize: 36,
                        color: context.colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user.displayName ?? 'User',
                    style: context.textTheme.headlineSmall,
                  ),
                  Text(user.email, style: context.textTheme.bodyMedium),
                  const SizedBox(height: 32),
                  TextFormField(
                    controller: _salaryController,
                    decoration: const InputDecoration(
                      labelText: UserConstants.salaryLabel,
                      prefixIcon: Icon(Icons.payments_outlined),
                      helperText: 'Encrypted before saving to Firestore',
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
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
                ],
              ),
            ),
    );
  }
}
