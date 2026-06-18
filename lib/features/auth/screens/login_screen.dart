import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/route_constants.dart';
import '../../../core/constants/l10n/locale_provider.dart';
import '../../../core/services/toast_service.dart';
import '../../../core/utils/extensions.dart';
import '../../../core/widgets/language_selector.dart';
import '../provider/auth_provider.dart';
import '../utils/auth_navigation.dart';
import '../widgets/auth_text_field.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController(text: '+92');
  bool _usePhoneLogin = false;
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _isPhoneLoading = false;
  String? _authError;
  bool _emailError = false;
  bool _passwordError = false;
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: AppConstants.animationDuration,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _clearAuthError() {
    if (_authError != null) {
      setState(() {
        _authError = null;
        _emailError = false;
        _passwordError = false;
      });
    }
  }

  void _applyAuthError(String error) {
    final s = ref.read(stringsProvider);
    final localized = s.translateAuthError(error);
    final lower = localized.toLowerCase();
    setState(() {
      _authError = localized;
      _emailError = lower.contains('email') ||
          lower.contains('account') ||
          lower.contains('register') ||
          lower.contains('ای میل') ||
          lower.contains('بريد');
      _passwordError = lower.contains('password') ||
          lower.contains('incorrect') ||
          lower.contains('پاس') ||
          lower.contains('مرور');
    });
    ToastService.error(context, localized);
  }

  Future<void> _handleLogin() async {
    _clearAuthError();
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final error = await ref.read(authNotifierProvider.notifier).signIn(
          _emailController.text,
          _passwordController.text,
        );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (error != null) {
      _applyAuthError(error);
      return;
    }

    final user = ref.read(authNotifierProvider).value;
    final s = ref.read(stringsProvider);
    if (user != null) {
      navigateAfterAuth(context, user);
      ToastService.success(
        context,
        s.welcomeBack(user.displayName ?? user.email),
      );
    }
  }

  Future<void> _handleGoogleSignIn() async {
    _clearAuthError();
    setState(() => _isGoogleLoading = true);

    final error = await ref.read(authNotifierProvider.notifier).signInWithGoogle();

    if (!mounted) return;
    setState(() => _isGoogleLoading = false);

    if (error != null) {
      _applyAuthError(error);
      return;
    }

    final user = ref.read(authNotifierProvider).value;
    final s = ref.read(stringsProvider);
    if (user != null) {
      navigateAfterAuth(context, user);
      ToastService.success(
        context,
        s.welcomeBack(user.displayName ?? user.email),
      );
      return;
    }

    _applyAuthError(
      'Google sign-in did not complete. Please try again or use email sign-in.',
    );
  }

  Future<void> _handlePhoneSignIn() async {
    _clearAuthError();
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isPhoneLoading = true);

    final error = await ref
        .read(authNotifierProvider.notifier)
        .signInWithPhone(_phoneController.text, _passwordController.text);

    if (!mounted) return;
    setState(() => _isPhoneLoading = false);

    if (error != null) {
      _applyAuthError(error);
      return;
    }

    final user = ref.read(authNotifierProvider).value;
    final s = ref.read(stringsProvider);
    if (user != null) {
      navigateAfterAuth(context, user);
      ToastService.success(
        context,
        s.welcomeBack(user.displayName ?? user.phone ?? user.email),
      );
      return;
    }

    _applyAuthError('Phone sign-in did not complete. Please try again.');
  }

  bool get _isBusy => _isLoading || _isGoogleLoading || _isPhoneLoading;

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);

    return Scaffold(
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: LanguageSelectorButton(),
                  ),
                  const SizedBox(height: 24),
                  Hero(
                    tag: 'rozgar_logo',
                    child: Icon(
                      Icons.work_outline_rounded,
                      size: 64,
                      color: context.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    AppConstants.appName,
                    textAlign: TextAlign.center,
                    style: context.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: context.colorScheme.primary,
                    ),
                  ),
                  Text(
                    s.appTagline,
                    textAlign: TextAlign.center,
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 48),
                  if (_authError != null) ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: context.colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: context.colorScheme.error.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: context.colorScheme.error,
                            size: 22,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _authError!,
                              style: TextStyle(
                                color: context.colorScheme.onErrorContainer,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  SegmentedButton<bool>(
                    segments: [
                      ButtonSegment(
                        value: false,
                        label: Text(s.signInWithEmail),
                        icon: const Icon(Icons.email_outlined, size: 18),
                      ),
                      ButtonSegment(
                        value: true,
                        label: Text(s.signInWithPhoneTab),
                        icon: const Icon(Icons.phone_outlined, size: 18),
                      ),
                    ],
                    selected: {_usePhoneLogin},
                    onSelectionChanged: (value) {
                      setState(() {
                        _usePhoneLogin = value.first;
                        _clearAuthError();
                      });
                    },
                  ),
                  const SizedBox(height: 24),
                  if (!_usePhoneLogin) ...[
                    AuthTextField(
                      controller: _emailController,
                      label: s.email,
                      hint: 'you@example.com',
                      keyboardType: TextInputType.emailAddress,
                      prefixIcon: Icons.email_outlined,
                      onChanged: (_) => _clearAuthError(),
                      validator: (v) {
                        if (!_usePhoneLogin) {
                          if (v == null || v.isEmpty) return s.emailRequired;
                          if (!v.isValidEmail) return s.validEmail;
                        }
                        return null;
                      },
                    ),
                    if (_emailError) ...[
                      const SizedBox(height: 6),
                      Text(
                        s.checkEmail,
                        style: TextStyle(
                          color: context.colorScheme.error,
                          fontSize: 12,
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    AuthTextField(
                      controller: _passwordController,
                      label: s.password,
                      hint: '••••••••',
                      obscureText: true,
                      prefixIcon: Icons.lock_outline,
                      onChanged: (_) => _clearAuthError(),
                      validator: (v) {
                        if (!_usePhoneLogin) {
                          if (v == null || v.isEmpty) return s.passwordRequired;
                          if (v.length < 6) return s.passwordMin6;
                        }
                        return null;
                      },
                    ),
                    if (_passwordError) ...[
                      const SizedBox(height: 6),
                      Text(
                        s.checkPassword,
                        style: TextStyle(
                          color: context.colorScheme.error,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ] else ...[
                    Text(
                      s.phoneSignInSubtitle,
                      style: context.textTheme.bodySmall?.copyWith(
                        color: context.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),
                    AuthTextField(
                      controller: _phoneController,
                      label: s.mobileNumber,
                      hint: '+923001234567',
                      keyboardType: TextInputType.phone,
                      prefixIcon: Icons.phone_outlined,
                      onChanged: (_) => _clearAuthError(),
                      validator: (v) {
                        if (_usePhoneLogin) {
                          if (v == null || v.trim().length < 10) {
                            return s.validPhone;
                          }
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),
                    Text(
                      s.phoneHint,
                      style: context.textTheme.bodySmall?.copyWith(
                        color: context.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),
                    AuthTextField(
                      controller: _passwordController,
                      label: s.password,
                      hint: '••••••••',
                      obscureText: true,
                      prefixIcon: Icons.lock_outline,
                      onChanged: (_) => _clearAuthError(),
                      validator: (v) {
                        if (_usePhoneLogin) {
                          if (v == null || v.isEmpty) return s.passwordRequired;
                          if (v.length < 6) return s.passwordMin6;
                        }
                        return null;
                      },
                    ),
                    if (_passwordError) ...[
                      const SizedBox(height: 6),
                      Text(
                        s.checkPassword,
                        style: TextStyle(
                          color: context.colorScheme.error,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                  const SizedBox(height: 32),
                  if (!_usePhoneLogin) ...[
                    OutlinedButton.icon(
                      onPressed: _isBusy ? null : _handleGoogleSignIn,
                      icon: _isGoogleLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Image.network(
                              'https://www.google.com/favicon.ico',
                              width: 20,
                              height: 20,
                              errorBuilder: (_, _, _) =>
                                  const Icon(Icons.g_mobiledata, size: 24),
                            ),
                      label: Text(s.continueWithGoogle),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: Divider(color: Colors.grey.shade400)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(s.or, style: context.textTheme.bodySmall),
                        ),
                        Expanded(child: Divider(color: Colors.grey.shade400)),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                  ElevatedButton(
                    onPressed: _isBusy
                        ? null
                        : (_usePhoneLogin ? _handlePhoneSignIn : _handleLogin),
                    child: (_isLoading || _isPhoneLoading)
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(s.signIn),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => context.push(RouteConstants.register),
                    child: Text(s.noAccountRegister),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
