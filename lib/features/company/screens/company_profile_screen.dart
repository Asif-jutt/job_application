import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/providers/core_providers.dart';
import '../../../core/utils/extensions.dart';
import '../../auth/provider/auth_provider.dart';
import '../constants/company_constants.dart';

class CompanyProfileScreen extends ConsumerStatefulWidget {
  const CompanyProfileScreen({super.key});

  @override
  ConsumerState<CompanyProfileScreen> createState() =>
      _CompanyProfileScreenState();
}

class _CompanyProfileScreenState extends ConsumerState<CompanyProfileScreen> {
  bool _uploading = false;

  Future<void> _uploadLogo() async {
    final permission = ref.read(permissionServiceProvider);
    final result = await permission.requestMediaForUpload();
    if (result.isFailure) return;

    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;

    setState(() => _uploading = true);
    final uploadResult =
        await ref.read(cloudinaryServiceProvider).uploadImage(File(file.path));
    setState(() => _uploading = false);

    if (!mounted) return;
    uploadResult.when(
      success: (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Logo uploaded successfully')),
        );
      },
      failure: (msg, _) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authNotifierProvider).value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Company Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authNotifierProvider.notifier).signOut(),
          ),
        ],
      ),
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 48,
                    backgroundColor: context.colorScheme.secondaryContainer,
                    child: Icon(
                      Icons.business,
                      size: 48,
                      color: context.colorScheme.secondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user.displayName ?? 'Company',
                    style: context.textTheme.headlineSmall,
                  ),
                  Text(user.email),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: _uploading ? null : _uploadLogo,
                    icon: _uploading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.image_outlined),
                    label: const Text(CompanyConstants.logoUploadLabel),
                  ),
                ],
              ),
            ),
    );
  }
}
