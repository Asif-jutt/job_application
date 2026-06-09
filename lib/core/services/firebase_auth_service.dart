import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../utils/app_logger.dart';

class FirebaseAuthService {
  FirebaseAuthService({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance {
    if (kIsWeb) {
      _auth.setPersistence(Persistence.LOCAL);
    }
  }

  final FirebaseAuth _auth;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Ensures the auth token is ready before Firestore reads/writes (critical on web).
  Future<void> waitForAuthReady() async {
    final user = _auth.currentUser;
    if (user == null) return;
    await user.getIdToken(true);
    await user.reload();
    AppLogger.debug('Auth token ready for uid: ${user.uid}');
  }

  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    AppLogger.info('Signing in user: $email');
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    await waitForAuthReady();
    return credential;
  }

  Future<UserCredential> registerWithEmail({
    required String email,
    required String password,
  }) async {
    AppLogger.info('Registering user: $email');
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    await waitForAuthReady();
    return credential;
  }

  Future<void> updateDisplayName(String name) async {
    await _auth.currentUser?.updateDisplayName(name);
    await waitForAuthReady();
  }

  Future<void> signOut() => _auth.signOut();

  Future<void> sendPasswordReset(String email) =>
      _auth.sendPasswordResetEmail(email: email.trim());
}
