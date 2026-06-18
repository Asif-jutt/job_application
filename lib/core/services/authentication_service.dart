import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../features/auth/constants/auth_constants.dart';
import '../../features/auth/model/app_user.dart';
import '../models/user_role.dart';
import '../security/aes_encryption_service.dart';
import '../utils/app_logger.dart';
import '../utils/result.dart';
import 'firebase_auth_service.dart';
import 'firestore_service.dart';
import 'google_auth_service.dart';
import 'performance_service.dart';

/// Unified authentication: Email, Google, and Phone (auto-verify) + Firestore profiles.
class AuthenticationService {
  AuthenticationService({
    required FirebaseAuthService authService,
    required GoogleAuthService googleAuth,
    required FirestoreService firestore,
    required AesEncryptionService encryption,
    PerformanceService? performance,
  })  : _authService = authService,
        _googleAuth = googleAuth,
        _firestore = firestore,
        _encryption = encryption,
        _performance = performance ?? PerformanceService();

  final FirebaseAuthService _authService;
  final GoogleAuthService _googleAuth;
  final FirestoreService _firestore;
  final AesEncryptionService _encryption;
  final PerformanceService _performance;

  String? _verificationId;
  int? _resendToken;

  String? get verificationId => _verificationId;

  // ── Google Sign-In ──────────────────────────────────────────────────────

  Future<Result<AppUser>> signInWithGoogle() async {
    return _performance.trace('auth_google_sign_in', () async {
      final googleResult = await _googleAuth.signInWithGoogle();
      if (googleResult.isFailure) {
        return Failure(
          googleResult.when(success: (_) => '', failure: (m, _) => m),
        );
      }

      final credential =
          googleResult.when(success: (v) => v, failure: (_, _) => null);
      final fbUser = credential?.user;
      if (fbUser == null) {
        return const Failure('Google sign-in returned no user');
      }

      final doc = await _firestore.getUser(fbUser.uid);
      if (!doc.exists) {
        AppLogger.auth('New Google user — role selection required: ${fbUser.uid}');
        return Success(AppUser(
          uid: fbUser.uid,
          email: fbUser.email ?? '',
          role: UserRole.user,
          displayName: fbUser.displayName,
          photoUrl: fbUser.photoURL,
          authProvider: 'google',
          phoneVerified: true,
          needsRoleSelection: true,
        ));
      }

      final appUser = _parseAppUser(doc);
      AppLogger.auth(
        'Google user ready: ${appUser.uid} (phoneVerified=${appUser.phoneVerified})',
      );
      return Success(appUser);
    });
  }

  /// Saves Firestore profile after new Google/phone user picks a role.
  Future<Result<AppUser>> completeGoogleRoleSelection(UserRole role) async {
    final fbUser = _authService.currentUser;
    if (fbUser == null) {
      return const Failure('Please sign in first');
    }

    try {
      final appUser = await _saveNewUserProfile(
        fbUser: fbUser,
        role: role,
        isNewUser: true,
      );
      AppLogger.auth('Role selected: ${role.value} for ${fbUser.uid}');
      return Success(appUser);
    } catch (e, st) {
      AppLogger.severe('Role selection failed', e, st);
      return Failure('Failed to save role. Please try again.', e);
    }
  }

  // ── Phone linking (legacy — optional profile update) ────────────────────

  Future<Result<void>> sendPhoneOtp(String phoneNumber) async {
    final user = _authService.currentUser;
    if (user == null) {
      return const Failure('Please sign in with Google first');
    }

    final normalized = _normalizePhone(phoneNumber);
    if (normalized == null) {
      return const Failure('Enter a valid mobile number with country code (e.g. +923001234567)');
    }

    final completer = Completer<Result<void>>();

    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: normalized,
      timeout: const Duration(seconds: 60),
      forceResendingToken: _resendToken,
      verificationCompleted: (PhoneAuthCredential credential) async {
        AppLogger.auth('Phone auto-verification completed');
        if (!completer.isCompleted) {
          completer.complete(await _linkPhoneCredential(credential, normalized));
        }
      },
      verificationFailed: (FirebaseAuthException e) {
        AppLogger.auth('Phone verification failed: ${e.code}');
        if (!completer.isCompleted) {
          completer.complete(Failure(_mapPhoneError(e), e));
        }
      },
      codeSent: (String verificationId, int? resendToken) {
        _verificationId = verificationId;
        _resendToken = resendToken;
        AppLogger.auth('OTP sent to $normalized');
        if (!completer.isCompleted) {
          completer.complete(const Success(null));
        }
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        _verificationId = verificationId;
      },
    );

    return completer.future.timeout(
      const Duration(seconds: 90),
      onTimeout: () => const Failure('OTP request timed out. Please try again.'),
    );
  }

  Future<Result<AppUser>> verifyPhoneOtp({
    required String smsCode,
    required String phoneNumber,
  }) async {
    final verificationId = _verificationId;
    if (verificationId == null) {
      return const Failure('No OTP session. Request a new code.');
    }

    final normalized = _normalizePhone(phoneNumber);
    if (normalized == null) {
      return const Failure('Invalid phone number');
    }

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode.trim(),
      );

      final linkResult = await _linkPhoneCredential(credential, normalized);
      if (linkResult.isFailure) {
        return Failure(
          linkResult.when(success: (_) => '', failure: (m, _) => m),
        );
      }

      final fbUser = _authService.currentUser;
      if (fbUser == null) {
        return const Failure('Session expired. Sign in again.');
      }

      final appUser = await _markPhoneVerified(fbUser.uid, normalized);
      _verificationId = null;
      return Success(appUser);
    } on FirebaseAuthException catch (e) {
      return Failure(_mapPhoneError(e), e);
    } catch (e, st) {
      AppLogger.severe('OTP verification failed', e, st);
      return Failure('OTP verification failed. Please try again.', e);
    }
  }

  Future<Result<void>> _linkPhoneCredential(
    PhoneAuthCredential credential,
    String phoneNumber,
  ) async {
    final user = _authService.currentUser;
    if (user == null) {
      return const Failure('Not signed in');
    }

    try {
      if (user.phoneNumber != null && user.phoneNumber!.isNotEmpty) {
        await user.updatePhoneNumber(credential);
      } else {
        await user.linkWithCredential(credential);
      }
      await _authService.waitForAuthReady();
      await _markPhoneVerified(user.uid, phoneNumber);
      return const Success(null);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'credential-already-in-use') {
        return const Failure(
          'This phone number is linked to another account.',
        );
      }
      if (e.code == 'provider-already-linked') {
        await _markPhoneVerified(user.uid, phoneNumber);
        return const Success(null);
      }
      return Failure(_mapPhoneError(e), e);
    }
  }

  Future<AppUser> _markPhoneVerified(String uid, String phoneNumber) async {
    var data = <String, dynamic>{
      'phone': phoneNumber,
      'phoneVerified': true,
      'mobileNumber': phoneNumber,
    };
    data = _encryption.encryptFields(data, AuthConstants.sensitiveUserFields);

    await _authService.waitForAuthReady();
    await _firestore.setUser(uid, data);

    final doc = await _firestore.getUser(uid);
    return _parseAppUser(doc);
  }

  Future<AppUser> _saveNewUserProfile({
    required User fbUser,
    required UserRole role,
    required bool isNewUser,
  }) async {
    final authProvider = _resolveAuthProvider(fbUser);
    final phone = fbUser.phoneNumber ?? _authService.currentUser?.phoneNumber;

    var data = <String, dynamic>{
      'email': fbUser.email ?? '',
      'displayName': fbUser.displayName ?? phone ?? 'User',
      'photoUrl': fbUser.photoURL,
      'profileImage': fbUser.photoURL,
      'authProvider': authProvider,
      'authenticationProvider': authProvider,
      'role': role.value,
      'phoneVerified': true,
      if (isNewUser) 'createdAt': FieldValue.serverTimestamp(),
      if (phone != null && phone.isNotEmpty) ...{
        'phone': phone,
        'mobileNumber': phone,
      },
    };

    if (phone != null && phone.isNotEmpty) {
      data = _encryption.encryptFields(
        data,
        AuthConstants.sensitiveUserFields,
      );
    }

    if (isNewUser) {
      await _authService.waitForAuthReady();
      await _firestore.setUser(fbUser.uid, data);
    } else {
      await _authService.waitForAuthReady();
      await _firestore.setUser(fbUser.uid, {
        'photoUrl': fbUser.photoURL,
        'profileImage': fbUser.photoURL,
        'displayName': fbUser.displayName ?? 'User',
        'email': fbUser.email ?? '',
      });
    }

    final doc = await _firestore.getUser(fbUser.uid);
    return _parseAppUser(doc);
  }

  String _resolveAuthProvider(User fbUser) {
    if (fbUser.providerData.any((p) => p.providerId == 'google.com')) {
      return 'google';
    }
    if (fbUser.providerData.any((p) => p.providerId == 'phone')) {
      return 'phone';
    }
    return 'email';
  }

  AppUser _parseAppUser(DocumentSnapshot<Map<String, dynamic>> doc) {
    var data = Map<String, dynamic>.from(doc.data() ?? {});
    try {
      data = _encryption.decryptFields(
        data,
        AuthConstants.sensitiveUserFields,
      );
    } catch (e) {
      AppLogger.warning('Decryption skipped for ${doc.id}', e);
    }

    final phone = data['phone'] as String? ?? data['mobileNumber'] as String?;
    final authProvider = data['authProvider'] as String? ??
        data['authenticationProvider'] as String? ??
        'email';
    final phoneVerified = data['phoneVerified'] as bool? ??
        (_authService.currentUser?.phoneNumber?.isNotEmpty ?? false) ||
        (authProvider != 'google' && phone != null && phone.isNotEmpty);

    return AppUser(
      uid: doc.id,
      email: data['email'] as String? ?? '',
      role: UserRole.fromString(data['role'] as String?),
      displayName: data['displayName'] as String?,
      phone: phone,
      photoUrl: data['photoUrl'] as String? ?? data['profileImage'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      authProvider: authProvider,
      phoneVerified: phoneVerified,
    );
  }

  Future<void> signOut() async {
    await _googleAuth.signOut();
    await _authService.signOut();
    _verificationId = null;
    _resendToken = null;
  }

  String? _normalizePhone(String raw) {
    var phone = raw.trim().replaceAll(RegExp(r'[\s\-()]'), '');
    if (phone.isEmpty) return null;
    if (!phone.startsWith('+')) {
      if (phone.startsWith('0')) phone = phone.substring(1);
      phone = '+92$phone';
    }
    if (!RegExp(r'^\+\d{10,15}$').hasMatch(phone)) return null;
    return phone;
  }

  String _mapPhoneError(FirebaseAuthException e) {
    return switch (e.code) {
      'invalid-phone-number' => 'Invalid phone number format. Use +923001234567',
      'too-many-requests' => 'Too many OTP requests. Wait a few minutes.',
      'invalid-verification-code' => 'Incorrect OTP. Please check and try again.',
      'session-expired' => 'OTP expired. Request a new code.',
      'quota-exceeded' => 'SMS quota exceeded. Try again later.',
      'network-request-failed' => 'Network error. Check your connection.',
      _ => e.message ?? 'Phone verification error',
    };
  }
}
