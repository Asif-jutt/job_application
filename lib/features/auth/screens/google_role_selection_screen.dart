import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/l10n/locale_provider.dart';
import '../../../core/models/user_role.dart';
import '../../../core/services/toast_service.dart';
import '../../../core/utils/extensions.dart';
import '../provider/auth_provider.dart';
import '../utils/auth_navigation.dart';

/// First-time Google sign-up: pick Job Seeker, Recruiter, or Admin role.
class GoogleRoleSelectionScreen extends ConsumerStatefulWidget {
  const GoogleRoleSelectionScreen({super.key});

  @override
  ConsumerState<GoogleRoleSelectionScreen> createState() =>
      _GoogleRoleSelectionScreenState();
}

class _GoogleRoleSelectionScreenState
    extends ConsumerState<GoogleRoleSelectionScreen> {
  UserRole _selectedRole = UserRole.user;
  bool _isLoading = false;

  String _roleLabel(UserRole role, dynamic s) => switch (role) {
        UserRole.user => s.roleJobSeeker,
        UserRole.company => s.roleRecruiter,
        UserRole.admin => s.roleAdmin,
      };

  IconData _roleIcon(UserRole role) => switch (role) {
        UserRole.user => Icons.person_outline,
        UserRole.company => Icons.business_outlined,
        UserRole.admin => Icons.admin_panel_settings_outlined,
      };

  Future<void> _continue() async {
    setState(() => _isLoading = true);
    final error =
        await ref.read(authNotifierProvider.notifier).completeGoogleRole(
              _selectedRole,
            );
    if (!mounted) return;
    setState(() => _isLoading = false);

    final s = ref.read(stringsProvider);
    if (error != null) {
      ToastService.error(context, error);
      return;
    }

    final user = ref.read(authNotifierProvider).value;
    if (user != null) {
      ToastService.success(context, s.accountCreated);
      navigateAfterAuth(context, user);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final user = ref.watch(authNotifierProvider).value;

    return Scaffold(
      appBar: AppBar(
        title: Text(s.selectRole),
        automaticallyImplyLeading: false,
        actions: [
          TextButton(
            onPressed: () => ref.read(authNotifierProvider.notifier).signOut(),
            child: Text(s.signOut),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(
                Icons.how_to_reg_outlined,
                size: 72,
                color: context.colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                s.selectRole,
                textAlign: TextAlign.center,
                style: context.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                s.selectRoleGoogleHint,
                textAlign: TextAlign.center,
                style: context.textTheme.bodyMedium?.copyWith(
                  color: context.colorScheme.onSurfaceVariant,
                ),
              ),
              if (user?.displayName != null) ...[
                const SizedBox(height: 12),
                Text(
                  user!.displayName!,
                  textAlign: TextAlign.center,
                  style: context.textTheme.titleMedium?.copyWith(
                    color: context.colorScheme.primary,
                  ),
                ),
              ],
              const SizedBox(height: 32),
              ...UserRole.values.map((role) {
                final selected = _selectedRole == role;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Material(
                    color: selected
                        ? context.colorScheme.primaryContainer
                        : context.colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => setState(() => _selectedRole = role),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(
                              _roleIcon(role),
                              color: selected
                                  ? context.colorScheme.primary
                                  : context.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                _roleLabel(role, s),
                                style: context.textTheme.titleMedium?.copyWith(
                                  fontWeight: selected
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                ),
                              ),
                            ),
                            if (selected)
                              Icon(
                                Icons.check_circle,
                                color: context.colorScheme.primary,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
              const Spacer(),
              ElevatedButton(
                onPressed: _isLoading ? null : _continue,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(s.continue_),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
