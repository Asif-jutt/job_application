import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/utils/app_logger.dart';
import '../../../core/utils/result.dart';
import '../../auth/provider/auth_provider.dart';
import '../model/company_profile.dart';

final companyProfileProvider = StreamProvider<CompanyProfile?>((ref) {
  final user = ref.watch(authNotifierProvider).value;
  if (user == null) return Stream.value(null);

  return ref.watch(firestoreServiceProvider).watchUser(user.uid).map((doc) {
    if (!doc.exists) {
      return CompanyProfile(
        uid: user.uid,
        companyName: user.displayName ?? 'Company',
        email: user.email,
      );
    }
    final data = doc.data() ?? {};
    return CompanyProfile.fromMap(user.uid, data);
  });
});

final companyProfileRepositoryProvider = Provider<CompanyProfileRepository>((ref) {
  return CompanyProfileRepository(ref.watch(firestoreServiceProvider));
});

class CompanyProfileRepository {
  CompanyProfileRepository(this._firestore);
  final FirestoreService _firestore;

  Future<Result<void>> saveProfile({
    required String uid,
    String? companyName,
    String? industry,
    String? website,
    String? description,
    String? logoUrl,
  }) async {
    try {
      await _firestore.setUser(uid, {
        if (companyName != null) 'displayName': companyName,
        if (industry != null) 'industry': industry,
        if (website != null) 'website': website,
        if (description != null) 'description': description,
        if (logoUrl != null) 'photoUrl': logoUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return const Success(null);
    } catch (e, st) {
      AppLogger.severe('Company profile save failed', e, st);
      return Failure('Failed to save profile', e);
    }
  }
}
