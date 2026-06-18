import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/models/user_role.dart';
import '../../../core/security/aes_encryption_service.dart';
import '../../../core/services/authentication_service.dart';
import '../../../core/services/firebase_auth_service.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/services/performance_service.dart';
import '../../../core/utils/app_logger.dart';
import '../../../core/utils/result.dart';
import '../constants/auth_constants.dart';
import '../model/app_user.dart';
import '../utils/phone_normalizer.dart';

class AuthRepository {
  AuthRepository({
    required FirebaseAuthService authService,
    required AuthenticationService authenticationService,
    required FirestoreService firestore,
    required AesEncryptionService encryption,
    PerformanceService? performance,
  })  : _authService = authService,
        _authenticationService = authenticationService,
        _firestore = firestore,
        _encryption = encryption,
        _performance = performance ?? PerformanceService();

  final FirebaseAuthService _authService;
  final AuthenticationService _authenticationService;
  final FirestoreService _firestore;
  final AesEncryptionService _encryption;
  final PerformanceService _performance;

  Stream<User?> get authStateChanges => _authService.authStateChanges;

  AuthenticationService get authentication => _authenticationService;

  Future<Result<AppUser>> signInWithGoogle() =>
      _authenticationService.signInWithGoogle();

  Future<Result<AppUser>> signInWithPhone({
    required String phoneNumber,
    required String password,
  }) async {
    return _performance.trace('auth_phone_sign_in', () async {
      final normalized = PhoneNormalizer.normalize(phoneNumber);
      if (normalized == null) {
        return const Failure(
          'Enter a valid mobile number with country code (e.g. +923001234567)',
        );
      }

      final phoneKey = PhoneNormalizer.docId(normalized);
      final indexDoc = await _firestore.getPhoneIndex(phoneKey);
      if (!indexDoc.exists) {
        AppLogger.auth('Phone sign-in failed: no account for $normalized');
        return const Failure(
          'No account found with this phone number. Please register first.',
        );
      }

      final email = indexDoc.data()?['email'] as String?;
      if (email == null || email.isEmpty) {
        return const Failure(
          'No account found with this phone number. Please register first.',
        );
      }

      AppLogger.auth('Phone matched — signing in with linked email');
      return signIn(email: email, password: password);
    });
  }

  Future<Result<AppUser>> completeGoogleRoleSelection(UserRole role) =>
      _authenticationService.completeGoogleRoleSelection(role);

  Future<Result<void>> sendPhoneOtp(String phoneNumber) =>
      _authenticationService.sendPhoneOtp(phoneNumber);

  Future<Result<AppUser>> verifyPhoneOtp({
    required String smsCode,
    required String phoneNumber,
  }) =>
      _authenticationService.verifyPhoneOtp(
        smsCode: smsCode,
        phoneNumber: phoneNumber,
      );

  Future<Result<AppUser>> signIn({
    required String email,
    required String password,
  }) async {
    return _performance.trace('auth_sign_in', () async {
      try {
        AppLogger.auth('Sign in attempt for ${email.trim()}');
        final credential = await _authService.signInWithEmail(
          email: email.trim(),
          password: password,
        );
        final uid = credential.user!.uid;
        final user = await _loadOrCreateAppUser(uid);
        AppLogger.auth('Sign in successful: $uid (${user.role.value})');
        return Success(user);
      } on FirebaseAuthException catch (e) {
        final message = _mapAuthError(e);
        AppLogger.auth('Sign in failed: ${e.code} → $message');
        return Failure(message, e);
      } catch (e, st) {
        AppLogger.severe('Sign in failed', e, st);
        return Failure(_mapGenericError(e), e);
      }
    });
  }

  Future<Result<AppUser>> register({
    required String email,
    required String password,
    required String displayName,
    required UserRole role,
    String? phone,
  }) async {
    UserCredential? credential;
    try {
      final normalizedPhone =
          phone != null ? PhoneNormalizer.normalize(phone) : null;
      if (normalizedPhone == null) {
        return const Failure(
          'A valid phone number is required. Use country code, e.g. +923001234567',
        );
      }

      final phoneKey = PhoneNormalizer.docId(normalizedPhone);
      final existingPhone = await _firestore.getPhoneIndex(phoneKey);
      if (existingPhone.exists) {
        return const Failure(
          'This phone number is already registered. Sign in with phone instead.',
        );
      }

      credential = await _authService.registerWithEmail(
        email: email.trim(),
        password: password,
      );

      await _authService.updateDisplayName(displayName);

      final uid = credential.user!.uid;
      final userData = _buildUserData(
        email: email.trim(),
        displayName: displayName,
        role: role,
        phone: normalizedPhone,
      );

      await _writeUserProfile(uid, userData);
      await _firestore.setPhoneIndex(phoneKey, {
        'uid': uid,
        'email': email.trim(),
        'phone': normalizedPhone,
      });

      AppLogger.info('User registered and saved to Firestore: $uid');

      return Success(AppUser(
        uid: uid,
        email: email.trim(),
        role: role,
        displayName: displayName,
        phone: normalizedPhone,
        createdAt: DateTime.now(),
      ));
    } on FirebaseAuthException catch (e) {
      AppLogger.warning('Register auth error: ${e.code}');
      if (e.code == 'email-already-in-use') {
        AppLogger.info('Account exists — attempting sign in instead');
        return signIn(email: email, password: password);
      }
      return Failure(_mapAuthError(e), e);
    } catch (e, st) {
      AppLogger.severe('Registration failed', e, st);
      await _rollbackAuthUser(credential?.user);
      return Failure(_mapGenericError(e), e);
    }
  }

  Map<String, dynamic> _buildUserData({
    required String email,
    required String displayName,
    required UserRole role,
    String? phone,
  }) {
    var userData = <String, dynamic>{
      'email': email,
      'role': role.value,
      'displayName': displayName,
      'authProvider': 'email',
      'authenticationProvider': 'email',
      'phoneVerified': true,
      'createdAt': FieldValue.serverTimestamp(),
    };

    if (phone != null && phone.isNotEmpty) {
      userData['phone'] = phone;
      userData['mobileNumber'] = phone;
      userData['phoneLookup'] = PhoneNormalizer.docId(phone);
      userData = _encryption.encryptFields(
        userData,
        AuthConstants.sensitiveUserFields,
      );
    }

    return userData;
  }

  Future<void> _writeUserProfile(String uid, Map<String, dynamic> data) async {
    Object? lastError;
    for (var attempt = 1; attempt <= 3; attempt++) {
      try {
        await _authService.waitForAuthReady();
        await _firestore.setUser(uid, data);
        AppLogger.info('Firestore profile written for $uid (attempt $attempt)');
        return;
      } on FirebaseException catch (e) {
        lastError = e;
        AppLogger.warning('Firestore write attempt $attempt failed: ${e.code}');
        if (attempt < 3) {
          await Future<void>.delayed(Duration(milliseconds: 400 * attempt));
        }
      }
    }
    if (lastError is FirebaseException) {
      throw Exception(_mapFirestoreError(lastError));
    }
    throw Exception('Failed to save profile to database.');
  }

  Future<AppUser> _loadOrCreateAppUser(String uid) async {
    await _authService.waitForAuthReady();
    final doc = await _firestore.getUser(uid);

    if (!doc.exists) {
      final fbUser = _authService.currentUser;
      if (fbUser == null) throw Exception('User profile not found');

      final isGoogleUser = fbUser.providerData
          .any((provider) => provider.providerId == 'google.com');
      final isPhoneUser = fbUser.providerData
          .any((provider) => provider.providerId == 'phone');
      if (isGoogleUser || isPhoneUser) {
        AppLogger.auth(
          '${isPhoneUser ? 'Phone' : 'Google'} user without Firestore profile — role selection required',
        );
        return AppUser(
          uid: uid,
          email: fbUser.email ?? '',
          role: UserRole.user,
          displayName: fbUser.displayName ?? fbUser.phoneNumber,
          photoUrl: fbUser.photoURL,
          phone: fbUser.phoneNumber,
          authProvider: isPhoneUser ? 'phone' : 'google',
          phoneVerified: true,
          needsRoleSelection: true,
        );
      }

      AppLogger.warning('Profile missing for $uid — creating from Auth record');
      final userData = _buildUserData(
        email: fbUser.email ?? '',
        displayName: fbUser.displayName ?? 'User',
        role: UserRole.user,
      );
      await _writeUserProfile(uid, userData);
      return AppUser(
        uid: uid,
        email: fbUser.email ?? '',
        role: UserRole.user,
        displayName: fbUser.displayName ?? 'User',
        createdAt: DateTime.now(),
      );
    }

    return _parseAppUser(doc);
  }

  AppUser _parseAppUser(DocumentSnapshot<Map<String, dynamic>> doc) {
    var data = Map<String, dynamic>.from(doc.data()!);
    try {
      data = _encryption.decryptFields(
        data,
        AuthConstants.sensitiveUserFields,
      );
    } catch (e) {
      AppLogger.warning('Decryption skipped for ${doc.id}', e);
    }

    return AppUser(
      uid: doc.id,
      email: data['email'] as String? ?? '',
      role: UserRole.fromString(data['role'] as String?),
      displayName: data['displayName'] as String?,
      phone: data['phone'] as String? ?? data['mobileNumber'] as String?,
      photoUrl: data['photoUrl'] as String? ?? data['profileImage'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      authProvider: data['authProvider'] as String? ??
          data['authenticationProvider'] as String? ??
          'email',
      phoneVerified: data['phoneVerified'] as bool? ??
          ((data['authProvider'] as String? ?? 'email') != 'google'),
      needsRoleSelection: false,
    );
  }

  Future<Result<AppUser>> getCurrentAppUser() async {
    final firebaseUser = _authService.currentUser;
    if (firebaseUser == null) {
      return const Failure('Not authenticated');
    }
    try {
      final user = await _loadOrCreateAppUser(firebaseUser.uid);
      return Success(user);
    } catch (e, st) {
      AppLogger.severe('Fetch user failed', e, st);
      return Failure(_mapGenericError(e), e);
    }
  }

  Future<void> signOut() => _authenticationService.signOut();

  Future<void> _rollbackAuthUser(User? user) async {
    try {
      await user?.delete();
    } catch (e) {
      AppLogger.warning('Could not rollback auth user', e);
    }
  }

  String _mapAuthError(FirebaseAuthException e) {
    return switch (e.code) {
      'user-not-found' =>
        'No account exists with this email address. Please register first.',
      'wrong-password' =>
        'Incorrect password. Please check your password and try again.',
      'invalid-credential' =>
        'The email or password is incorrect. Please verify both and try again.',
      'invalid-email' => 'Please enter a valid email address.',
      'too-many-requests' =>
        'Too many failed attempts. Please wait a few minutes and try again.',
      'network-request-failed' =>
        'Network error. Check your internet connection and try again.',
      'email-already-in-use' =>
        'An account already exists. Try signing in instead.',
      'weak-password' => 'Password is too weak (min 6 characters).',
      'operation-not-allowed' =>
        'Email/password sign-in is disabled. Enable it in Firebase Console → Authentication.',
      _ => e.message ?? 'Authentication error occurred.',
    };
  }

  String _mapFirestoreError(FirebaseException e) {
    return switch (e.code) {
      'permission-denied' =>
        'Database permission denied. Check Firestore rules in Firebase Console.',
      'unavailable' => 'Database unavailable. Check your internet connection.',
      _ => 'Database error: ${e.message ?? e.code}',
    };
  }

  String _mapGenericError(Object e) {
    final msg = e.toString();
    if (msg.contains('permission-denied') || msg.contains('PERMISSION_DENIED')) {
      return 'Database permission denied. Check Firestore rules.';
    }
    if (e is Exception && e.toString().startsWith('Exception: ')) {
      return e.toString().replaceFirst('Exception: ', '');
    }
    return 'Something went wrong. Please try again.';
  }
}
