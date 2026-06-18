import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/l10n/locale_provider.dart';
import '../../../core/constants/route_constants.dart';
import '../../../core/services/toast_service.dart';
import '../../../core/utils/extensions.dart';
import '../provider/auth_provider.dart';
import '../provider/phone_verification_provider.dart';
import '../utils/auth_navigation.dart';

/// Step 7–8: enter and verify SMS OTP from Firebase Phone Auth.
class OtpVerificationScreen extends ConsumerStatefulWidget {
  const OtpVerificationScreen({super.key});

  @override
  ConsumerState<OtpVerificationScreen> createState() =>
      _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends ConsumerState<OtpVerificationScreen> {
  final _otpController = TextEditingController();
  bool _isLoading = false;
  bool _isResending = false;

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final phone = ref.read(pendingPhoneProvider);
    if (phone == null) {
      context.go(RouteConstants.phoneVerify);
      return;
    }

    final code = _otpController.text.trim();
    if (code.length < 6) {
      ToastService.error(context, ref.read(stringsProvider).enterOtp);
      return;
    }

    setState(() => _isLoading = true);
    final error = await ref.read(authNotifierProvider.notifier).verifyPhoneOtp(
          smsCode: code,
          phoneNumber: phone,
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
      ref.read(pendingPhoneProvider.notifier).state = null;
      ToastService.success(context, s.phoneVerified);
      navigateToRoleHome(context, user);
    }
  }

  Future<void> _resend() async {
    final phone = ref.read(pendingPhoneProvider);
    if (phone == null) return;

    setState(() => _isResending = true);
    final error =
        await ref.read(authNotifierProvider.notifier).sendPhoneOtp(phone);
    if (!mounted) return;
    setState(() => _isResending = false);

    if (error != null) {
      ToastService.error(context, error);
    } else {
      ToastService.success(context, ref.read(stringsProvider).otpSent);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final phone = ref.watch(pendingPhoneProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(s.enterOtpTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(RouteConstants.phoneVerify),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(
                Icons.sms_outlined,
                size: 64,
                color: context.colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                s.enterOtpTitle,
                textAlign: TextAlign.center,
                style: context.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                phone != null ? s.otpSentTo(phone) : s.enterOtp,
                textAlign: TextAlign.center,
                style: context.textTheme.bodyMedium,
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                maxLength: 6,
                style: context.textTheme.headlineMedium?.copyWith(
                  letterSpacing: 12,
                  fontWeight: FontWeight.bold,
                ),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  hintText: '000000',
                  counterText: '',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onSubmitted: (_) => _verify(),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _verify,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(s.verifyOtp),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _isResending ? null : _resend,
                child: _isResending
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(s.resendOtp),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
