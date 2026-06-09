import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../../../core/security/aes_encryption_service.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/utils/app_logger.dart';
import '../../../core/utils/result.dart';
import '../../auth/constants/auth_constants.dart';
import '../../auth/provider/auth_provider.dart';
import '../constants/user_constants.dart';
import '../model/user_profile.dart';

final userProfileProvider = StreamProvider<UserProfile?>((ref) {
  final user = ref.watch(authNotifierProvider).value;
  if (user == null) return Stream.value(null);

  final encryption = ref.watch(aesEncryptionProvider);

  return ref.watch(firestoreServiceProvider).watchUser(user.uid).map((doc) {
    if (!doc.exists) return null;
    var data = Map<String, dynamic>.from(doc.data()!);
    try {
      data = encryption.decryptFields(
        data,
        UserConstants.sensitiveFields,
      );
    } catch (e) {
      AppLogger.warning('Profile decryption skipped', e);
    }
    return UserProfile.fromMap(user.uid, data);
  });
});

final userProfileRepositoryProvider = Provider<UserProfileRepository>((ref) {
  return UserProfileRepository(
    firestore: ref.watch(firestoreServiceProvider),
    encryption: ref.watch(aesEncryptionProvider),
  );
});

class UserProfileRepository {
  UserProfileRepository({
    required FirestoreService firestore,
    required AesEncryptionService encryption,
  })  : _firestore = firestore,
        _encryption = encryption;

  final FirestoreService _firestore;
  final AesEncryptionService _encryption;

  Future<Result<void>> saveProfile({
    required String uid,
    String? headline,
    String? salary,
    String? cvUrl,
    String? photoUrl,
    List<String>? skills,
    List<Map<String, dynamic>>? education,
    List<Map<String, dynamic>>? experience,
  }) async {
    try {
      var data = <String, dynamic>{
        if (headline != null) 'headline': headline,
        if (cvUrl != null) 'cvUrl': cvUrl,
        if (photoUrl != null) 'photoUrl': photoUrl,
        if (skills != null) 'skills': skills,
        if (education != null) 'education': education,
        if (experience != null) 'experience': experience,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (salary != null && salary.isNotEmpty) {
        data['salary'] = salary;
        data = _encryption.encryptFields(
          data,
          AuthConstants.sensitiveUserFields,
        );
      }

      await _firestore.setUser(uid, data);
      return const Success(null);
    } catch (e, st) {
      AppLogger.severe('Profile save failed', e, st);
      return Failure('Failed to save profile', e);
    }
  }
}
