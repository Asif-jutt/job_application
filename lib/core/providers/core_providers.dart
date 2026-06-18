import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/dio_client.dart';
import '../security/aes_encryption_service.dart';
import '../security/secure_storage_service.dart';
import '../services/ads_service.dart';
import '../services/app_diagnostics_service.dart';
import '../services/authentication_service.dart';
import '../services/chat_service.dart';
import '../services/cloudinary_service.dart';
import '../services/fcm_service.dart';
import '../services/firebase_auth_service.dart';
import '../services/firestore_service.dart';
import '../services/google_auth_service.dart';
import '../services/isolate_service.dart';
import '../services/job_repository.dart';
import '../services/job_seed_service.dart';
import '../services/local_notification_service.dart';
import '../services/performance_service.dart';
import '../services/permission_service.dart';
import '../services/workmanager_service.dart';

final secureStorageProvider = Provider<SecureStorageService>(
  (ref) => SecureStorageService(),
);

final aesEncryptionProvider = Provider<AesEncryptionService>((ref) {
  return AesEncryptionService(ref.watch(secureStorageProvider));
});

final dioClientProvider = Provider<DioClient>((ref) => DioClient());

final performanceServiceProvider = Provider<PerformanceService>(
  (ref) => PerformanceService(),
);

final firebaseAuthServiceProvider = Provider<FirebaseAuthService>(
  (ref) => FirebaseAuthService(),
);

final googleAuthServiceProvider = Provider<GoogleAuthService>((ref) {
  return GoogleAuthService(
    authService: ref.watch(firebaseAuthServiceProvider),
  );
});

final authenticationServiceProvider = Provider<AuthenticationService>((ref) {
  return AuthenticationService(
    authService: ref.watch(firebaseAuthServiceProvider),
    googleAuth: ref.watch(googleAuthServiceProvider),
    firestore: ref.watch(firestoreServiceProvider),
    encryption: ref.watch(aesEncryptionProvider),
    performance: ref.watch(performanceServiceProvider),
  );
});

final firestoreServiceProvider = Provider<FirestoreService>(
  (ref) => FirestoreService(),
);

final jobRepositoryProvider = Provider<JobRepository>((ref) {
  return JobRepository(
    firestore: ref.watch(firestoreServiceProvider),
    dioClient: ref.watch(dioClientProvider),
    performance: ref.watch(performanceServiceProvider),
  );
});

final chatServiceProvider = Provider<ChatService>(
  (ref) => ChatService(ref.watch(firestoreServiceProvider)),
);

final jobSeedServiceProvider = Provider<JobSeedService>(
  (ref) => JobSeedService(ref.watch(firestoreServiceProvider)),
);

final cloudinaryServiceProvider = Provider<CloudinaryService>(
  (ref) => CloudinaryService(
    performanceService: ref.watch(performanceServiceProvider),
  ),
);

final adsServiceProvider = Provider<AdsService>((ref) => AdsService());

final fcmServiceProvider = Provider<FcmService>((ref) => FcmService(
      localNotifications: ref.watch(localNotificationProvider),
    ));

final localNotificationProvider = Provider<LocalNotificationService>(
  (ref) => LocalNotificationService(),
);

final permissionServiceProvider = Provider<PermissionService>(
  (ref) => PermissionService(),
);

final workmanagerServiceProvider = Provider<WorkmanagerService>(
  (ref) => WorkmanagerService(),
);

final isolateServiceProvider = Provider<IsolateService>(
  (ref) => IsolateService(),
);

final appDiagnosticsProvider = Provider<AppDiagnosticsService>((ref) {
  return AppDiagnosticsService(encryption: ref.watch(aesEncryptionProvider));
});
