import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/l10n/locale_provider.dart';
import '../../../core/constants/route_constants.dart';
import '../../../core/services/toast_service.dart';
import '../../../core/utils/extensions.dart';
import '../provider/auth_provider.dart';
import '../provider/phone_verification_provider.dart';
import '../widgets/auth_text_field.dart';

/// Step 5–6: collect mobile number and send Firebase OTP (2FA after Google).
class PhoneVerificationScreen extends ConsumerStatefulWidget {
  const PhoneVerificationScreen({super.key});

  @override
  ConsumerState<PhoneVerificationScreen> createState() =>
      _PhoneVerificationScreenState();
}

class _PhoneVerificationScreenState
    extends ConsumerState<PhoneVerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController(text: '+92');
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final phone = _phoneController.text.trim();
    final error = await ref.read(authNotifierProvider.notifier).sendPhoneOtp(phone);

    if (!mounted) return;
    setState(() => _isLoading = false);

    final s = ref.read(stringsProvider);
    if (error != null) {
      ToastService.error(context, error);
      return;
    }

    ref.read(pendingPhoneProvider.notifier).state = phone;
    ToastService.success(context, s.otpSent);
    context.push(RouteConstants.otpVerify);
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final user = ref.watch(authNotifierProvider).value;

    return Scaffold(
      appBar: AppBar(
        title: Text(s.verifyPhone),
        automaticallyImplyLeading: false,
        actions: [
          TextButton(
            onPressed: () => ref.read(authNotifierProvider.notifier).signOut(),
            child: Text(s.signOut),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  Icons.phone_android_rounded,
                  size: 72,
                  color: context.colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  s.twoFactorTitle,
                  textAlign: TextAlign.center,
                  style: context.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  s.twoFactorSubtitle,
                  textAlign: TextAlign.center,
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: context.colorScheme.onSurfaceVariant,
                  ),
                ),
                if (user?.email.isNotEmpty == true) ...[
                  const SizedBox(height: 12),
                  Text(
                    user!.email,
                    textAlign: TextAlign.center,
                    style: context.textTheme.labelLarge?.copyWith(
                      color: context.colorScheme.primary,
                    ),
                  ),
                ],
                const SizedBox(height: 32),
                AuthTextField(
                  controller: _phoneController,
                  label: s.mobileNumber,
                  hint: '+923001234567',
                  keyboardType: TextInputType.phone,
                  prefixIcon: Icons.phone_outlined,
                  validator: (v) {
                    if (v == null || v.trim().length < 10) {
                      return s.validPhone;
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
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _isLoading ? null : _sendOtp,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(s.sendOtp),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
