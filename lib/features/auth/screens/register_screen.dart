import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/l10n/app_strings.dart';
import '../../../core/constants/l10n/locale_provider.dart';
import '../../../core/models/user_role.dart';
import '../../../core/utils/extensions.dart';
import '../../../core/widgets/language_selector.dart';
import '../provider/auth_provider.dart';
import '../utils/auth_navigation.dart';
import '../widgets/auth_text_field.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController(text: '+92');
  UserRole _selectedRole = UserRole.user;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  String _roleLabel(UserRole role, AppStrings s) => switch (role) {
        UserRole.user => s.roleJobSeeker,
        UserRole.company => s.roleRecruiter,
        UserRole.admin => s.roleAdmin,
      };

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final error = await ref.read(authNotifierProvider.notifier).register(
          email: _emailController.text,
          password: _passwordController.text,
          displayName: _nameController.text,
          role: _selectedRole,
          phone: _phoneController.text.isNotEmpty
              ? _phoneController.text
              : null,
        );

    if (!mounted) return;
    setState(() => _isLoading = false);
    final s = ref.read(stringsProvider);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(s.translateAuthError(error)),
          backgroundColor: context.colorScheme.error,
        ),
      );
      return;
    }

    final user = ref.read(authNotifierProvider).value;
    if (user != null) {
      navigateToRoleHome(context, user);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.accountCreated)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(s.createAccount),
        actions: const [LanguageSelectorButton()],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  s.joinApp(AppConstants.appName),
                  style: context.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  s.selectRole,
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 24),
                AnimatedSwitcher(
                  duration: AppConstants.animationDuration,
                  child: SegmentedButton<UserRole>(
                    key: ValueKey(_selectedRole),
                    segments: UserRole.values
                        .map((r) => ButtonSegment(
                              value: r,
                              label: Text(_roleLabel(r, s)),
                              icon: Icon(_roleIcon(r)),
                            ))
                        .toList(),
                    selected: {_selectedRole},
                    onSelectionChanged: (sel) =>
                        setState(() => _selectedRole = sel.first),
                  ),
                ),
                const SizedBox(height: 24),
                AuthTextField(
                  controller: _nameController,
                  label: s.fullName,
                  prefixIcon: Icons.person_outline,
                  validator: (v) =>
                      v == null || v.isEmpty ? s.nameRequired : null,
                ),
                const SizedBox(height: 16),
                AuthTextField(
                  controller: _emailController,
                  label: s.email,
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: Icons.email_outlined,
                  validator: (v) {
                    if (v == null || v.isEmpty) return s.emailRequired;
                    if (!v.isValidEmail) return s.validEmail;
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                AuthTextField(
                  controller: _phoneController,
                  label: s.phoneEncrypted,
                  keyboardType: TextInputType.phone,
                  prefixIcon: Icons.phone_outlined,
                  validator: (v) {
                    if (v == null || v.trim().length < 10) return s.validPhone;
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                AuthTextField(
                  controller: _passwordController,
                  label: s.password,
                  obscureText: true,
                  prefixIcon: Icons.lock_outline,
                  validator: (v) {
                    if (v == null || v.length < 6) return s.passwordMin6;
                    return null;
                  },
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleRegister,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(s.createAccount),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => context.pop(),
                  child: Text(s.haveAccountSignIn),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _roleIcon(UserRole role) => switch (role) {
        UserRole.user => Icons.person,
        UserRole.company => Icons.business,
        UserRole.admin => Icons.admin_panel_settings,
      };
}
