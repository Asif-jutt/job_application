import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/user_role.dart';
import '../../../core/providers/core_providers.dart';
import '../model/app_user.dart';
import 'auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    authService: ref.watch(firebaseAuthServiceProvider),
    firestore: ref.watch(firestoreServiceProvider),
    encryption: ref.watch(aesEncryptionProvider),
  );
});

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

final currentAppUserProvider = FutureProvider<AppUser?>((ref) async {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (user) async {
      if (user == null) return null;
      final result = await ref.read(authRepositoryProvider).getCurrentAppUser();
      return result.dataOrNull;
    },
    loading: () => null,
    error: (_, _) => null,
  );
});

class AuthNotifier extends StateNotifier<AsyncValue<AppUser?>> {
  AuthNotifier(this._repository) : super(const AsyncValue.loading()) {
    _init();
  }

  final AuthRepository _repository;

  Future<void> _init() async {
    final result = await _repository.getCurrentAppUser();
    state = AsyncValue.data(result.dataOrNull);
  }

  Future<String?> signIn(String email, String password) async {
    state = const AsyncValue.loading();
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
  }

  Future<String?> register({
    required String email,
    required String password,
    required String displayName,
    required UserRole role,
    String? phone,
  }) async {
    state = const AsyncValue.loading();
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
  }

  Future<void> signOut() async {
    await _repository.signOut();
    state = const AsyncValue.data(null);
  }
}

final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<AppUser?>>((ref) {
  return AuthNotifier(ref.watch(authRepositoryProvider));
});
