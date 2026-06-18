import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/user_role.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/utils/app_logger.dart';
import '../model/app_user.dart';
import 'auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    authService: ref.watch(firebaseAuthServiceProvider),
    authenticationService: ref.watch(authenticationServiceProvider),
    firestore: ref.watch(firestoreServiceProvider),
    encryption: ref.watch(aesEncryptionProvider),
    performance: ref.watch(performanceServiceProvider),
  );
});

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

class AuthNotifier extends StateNotifier<AsyncValue<AppUser?>> {
  AuthNotifier(this._repository) : super(const AsyncValue.loading()) {
    _init();
  }

  final AuthRepository _repository;
  StreamSubscription<User?>? _authSubscription;
  bool _isAuthenticating = false;

  void _init() {
    _authSubscription = _repository.authStateChanges.listen(
      (firebaseUser) async {
        if (_isAuthenticating) return;
        if (firebaseUser == null) {
          state = const AsyncValue.data(null);
          return;
        }
        if (state.value?.uid == firebaseUser.uid) return;
        await _loadAppUser(silent: true);
      },
      onError: (Object e, StackTrace st) {
        AppLogger.error('Auth stream error', e, st);
        if (!_isAuthenticating) state = const AsyncValue.data(null);
      },
    );

    unawaited(_loadAppUser(silent: true));
  }

  Future<void> _loadAppUser({bool silent = false}) async {
    if (!silent) state = const AsyncValue.loading();
    try {
      final result = await _repository
          .getCurrentAppUser()
          .timeout(const Duration(seconds: 15));
      result.when(
        success: (user) => state = AsyncValue.data(user),
        failure: (message, _) {
          if (message != 'Not authenticated') {
            AppLogger.warning('Profile load failed: $message');
          }
          if (state.value == null) state = const AsyncValue.data(null);
        },
      );
    } on TimeoutException {
      AppLogger.warning('Auth profile load timed out');
      if (state.value == null) state = const AsyncValue.data(null);
    } catch (e, st) {
      AppLogger.error('Auth profile load failed', e, st);
      if (state.value == null) state = const AsyncValue.data(null);
    }
  }

  Future<String?> signIn(String email, String password) async {
    _isAuthenticating = true;
    state = const AsyncValue.loading();
    try {
      final result = await _repository.signIn(email: email, password: password);
      return result.when(
        success: (user) {
          state = AsyncValue.data(user);
          return null;
        },
        failure: (message, _) {
          state = const AsyncValue.data(null);
          return message;
        },
      );
    } finally {
      _isAuthenticating = false;
    }
  }

  Future<String?> register({
    required String email,
    required String password,
    required String displayName,
    required UserRole role,
    String? phone,
  }) async {
    _isAuthenticating = true;
    state = const AsyncValue.loading();
    try {
      final result = await _repository.register(
        email: email,
        password: password,
        displayName: displayName,
        role: role,
        phone: phone,
      );
      return result.when(
        success: (user) {
          state = AsyncValue.data(user);
          return null;
        },
        failure: (message, _) {
          state = const AsyncValue.data(null);
          return message;
        },
      );
    } finally {
      _isAuthenticating = false;
    }
  }

  Future<void> signOut() async {
    await _repository.signOut();
    state = const AsyncValue.data(null);
  }

  Future<String?> signInWithGoogle() async {
    _isAuthenticating = true;
    state = const AsyncValue.loading();
    try {
      final result = await _repository.signInWithGoogle();
      return result.when(
        success: (user) {
          state = AsyncValue.data(user);
          return null;
        },
        failure: (message, _) {
          state = const AsyncValue.data(null);
          return message;
        },
      );
    } finally {
      // Keep listener paused until Riverpod/router consume the new user.
      await Future<void>.delayed(const Duration(milliseconds: 300));
      _isAuthenticating = false;
    }
  }

  Future<String?> signInWithPhone(
    String phoneNumber,
    String password,
  ) async {
    _isAuthenticating = true;
    state = const AsyncValue.loading();
    try {
      final result = await _repository.signInWithPhone(
        phoneNumber: phoneNumber,
        password: password,
      );
      return result.when(
        success: (user) {
          state = AsyncValue.data(user);
          return null;
        },
        failure: (message, _) {
          state = const AsyncValue.data(null);
          return message;
        },
      );
    } finally {
      await Future<void>.delayed(const Duration(milliseconds: 300));
      _isAuthenticating = false;
    }
  }

  Future<String?> completeGoogleRole(UserRole role) async {
    state = const AsyncValue.loading();
    final result = await _repository.completeGoogleRoleSelection(role);
    return result.when(
      success: (user) {
        state = AsyncValue.data(user);
        return null;
      },
      failure: (message, _) {
        state = AsyncValue.data(state.value);
        return message;
      },
    );
  }

  Future<String?> sendPhoneOtp(String phoneNumber) async {
    final result = await _repository.sendPhoneOtp(phoneNumber);
    return result.when(
      success: (_) => null,
      failure: (message, _) => message,
    );
  }

  Future<String?> verifyPhoneOtp({
    required String smsCode,
    required String phoneNumber,
  }) async {
    final result = await _repository.verifyPhoneOtp(
      smsCode: smsCode,
      phoneNumber: phoneNumber,
    );
    return result.when(
      success: (user) {
        state = AsyncValue.data(user);
        return null;
      },
      failure: (message, _) => message,
    );
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}

final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<AppUser?>>((ref) {
  return AuthNotifier(ref.watch(authRepositoryProvider));
});
