import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/models/user_role.dart';
import '../../../core/security/aes_encryption_service.dart';
import '../../../core/services/firebase_auth_service.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/utils/app_logger.dart';
import '../../../core/utils/result.dart';
import '../constants/auth_constants.dart';
import '../model/app_user.dart';

class AuthRepository {
  AuthRepository({
    required FirebaseAuthService authService,
    required FirestoreService firestore,
    required AesEncryptionService encryption,
  })  : _authService = authService,
        _firestore = firestore,
        _encryption = encryption;

  final FirebaseAuthService _authService;
  final FirestoreService _firestore;
  final AesEncryptionService _encryption;

  Stream<User?> get authStateChanges => _authService.authStateChanges;

  Future<Result<AppUser>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _authService.signInWithEmail(
        email: email.trim(),
        password: password,
      );
      final user = await _loadAppUser(credential.user!.uid);
      return Success(user);
    } on FirebaseAuthException catch (e) {
      return Failure(_mapAuthError(e), e);
    } catch (e, st) {
      AppLogger.severe('Sign in failed', e, st);
      return Failure('Sign in failed', e);
    }
  }

  Future<Result<AppUser>> register({
    required String email,
    required String password,
    required String displayName,
    required UserRole role,
    String? phone,
  }) async {
    try {
      final credential = await _authService.registerWithEmail(
        email: email.trim(),
        password: password,
      );

      final uid = credential.user!.uid;
      var userData = <String, dynamic>{
        'email': email.trim(),
        'role': role.value,
        'displayName': displayName,
        'phone': phone,
        'createdAt': FieldValue.serverTimestamp(),
      };

      if (phone != null && phone.isNotEmpty) {
        userData = _encryption.encryptFields(
          userData,
          AuthConstants.sensitiveUserFields,
        );
      }

      await _firestore.setUser(uid, userData);

      return Success(AppUser(
        uid: uid,
        email: email.trim(),
        role: role,
        displayName: displayName,
        phone: phone,
        createdAt: DateTime.now(),
      ));
    } on FirebaseAuthException catch (e) {
      return Failure(_mapAuthError(e), e);
    } catch (e, st) {
      AppLogger.severe('Registration failed', e, st);
      return Failure('Registration failed', e);
    }
  }

  Future<AppUser> _loadAppUser(String uid) async {
    final doc = await _firestore.getUser(uid);
    if (!doc.exists) throw Exception('User profile not found');

    var data = Map<String, dynamic>.from(doc.data()!);
    data = _encryption.decryptFields(
      data,
      AuthConstants.sensitiveUserFields,
    );

    return AppUser(
      uid: doc.id,
      email: data['email'] as String? ?? '',
      role: UserRole.fromString(data['role'] as String?),
      displayName: data['displayName'] as String?,
      phone: data['phone'] as String?,
      photoUrl: data['photoUrl'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Future<Result<AppUser>> getCurrentAppUser() async {
    final firebaseUser = _authService.currentUser;
    if (firebaseUser == null) {
      return const Failure('Not authenticated');
    }
    try {
      final user = await _loadAppUser(firebaseUser.uid);
      return Success(user);
    } catch (e, st) {
      AppLogger.severe('Fetch user failed', e, st);
      return Failure('Failed to load user profile', e);
    }
  }

  Future<void> signOut() => _authService.signOut();

  String _mapAuthError(FirebaseAuthException e) {
    return switch (e.code) {
      'user-not-found' => 'No account found with this email.',
      'wrong-password' => 'Incorrect password.',
      'email-already-in-use' => 'An account already exists with this email.',
      'weak-password' => 'Password is too weak.',
      'invalid-email' => 'Invalid email address.',
      _ => e.message ?? 'Authentication error occurred.',
    };
  }
}
