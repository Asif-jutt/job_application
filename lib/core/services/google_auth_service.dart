import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../features/auth/constants/auth_constants.dart';
import '../utils/app_logger.dart';
import '../utils/result.dart';
import 'firebase_auth_service.dart';

/// Google Sign-In via [google_sign_in] + Firebase Auth credential exchange.
class GoogleAuthService {
  GoogleAuthService({
    FirebaseAuth? auth,
    GoogleSignIn? googleSignIn,
    FirebaseAuthService? authService,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _googleSignIn = googleSignIn ??
            GoogleSignIn(
              scopes: const ['email', 'profile'],
              serverClientId: AuthConstants.googleWebClientId,
            ),
        _authService = authService ?? FirebaseAuthService(auth: auth);

  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;
  final FirebaseAuthService _authService;

  Future<Result<UserCredential>> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        final provider = GoogleAuthProvider();
        provider.addScope('email');
        provider.addScope('profile');
        final credential = await _auth.signInWithPopup(provider);
        await _authService.waitForAuthReady();
        AppLogger.auth('Google sign-in (web) successful: ${credential.user?.uid}');
        return Success(credential);
      }

      // Clear any cached Google session so account picker returns fresh tokens.
      try {
        await _googleSignIn.signOut();
      } catch (_) {}

      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return const Failure('Google sign-in was cancelled');
      }

      final googleAuth = await googleUser.authentication;
      AppLogger.auth(
        'Google tokens: idToken=${googleAuth.idToken != null}, '
        'accessToken=${googleAuth.accessToken != null}',
      );
      if (googleAuth.idToken == null) {
        AppLogger.auth('Google sign-in failed: idToken is null');
        return const Failure(
          'Google sign-in failed. Add your app SHA-1 fingerprint in Firebase Console '
          '(Project Settings → Your apps → Add fingerprint), then re-download google-services.json.',
        );
      }

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      await _authService.waitForAuthReady();
      AppLogger.auth(
        'Google sign-in successful: ${userCredential.user?.uid}',
      );
      return Success(userCredential);
    } on FirebaseAuthException catch (e) {
      AppLogger.auth('Google Firebase auth error: ${e.code}');
      return Failure(e.message ?? 'Google authentication failed', e);
    } catch (e, st) {
      AppLogger.severe('Google sign-in failed', e, st);
      final msg = e.toString();
      if (msg.contains('ApiException: 10') || msg.contains('sign_in_failed')) {
        return const Failure(
          'Google Sign-In is not configured for this app. Add your SHA-1 fingerprint '
          'in Firebase Console → Project Settings → Your Android app.',
        );
      }
      return Failure('Google sign-in failed. Check Firebase Google provider setup.', e);
    }
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (e) {
      AppLogger.warning('Google sign-out skipped', e);
    }
  }
}
