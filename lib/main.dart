import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/app_theme.dart';
import 'core/constants/app_constants.dart';
import 'core/providers/core_providers.dart';
import 'core/services/fcm_service.dart';
import 'core/utils/app_logger.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    const ProviderScope(
      child: RozgarBootstrap(),
    ),
  );
}

/// Initializes services inside the same [ProviderScope] used by the app.
class RozgarBootstrap extends ConsumerStatefulWidget {
  const RozgarBootstrap({super.key});

  @override
  ConsumerState<RozgarBootstrap> createState() => _RozgarBootstrapState();
}

class _RozgarBootstrapState extends ConsumerState<RozgarBootstrap> {
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _initializeFramework();
  }

  Future<void> _initializeFramework() async {
    AppLogger.info('Initializing Rozgar framework...');

    try {
      await ref.read(aesEncryptionProvider).initialize();

      if (!kIsWeb) {
        await _safeInit(
          'Local notifications',
          () => ref.read(localNotificationProvider).initialize(),
        );
        await _safeInit(
          'Permissions',
          () => ref.read(permissionServiceProvider).requestEssentialPermissions(),
        );
        await _safeInit(
          'WorkManager',
          () async {
            await ref.read(workmanagerServiceProvider).initialize();
            await ref.read(workmanagerServiceProvider).schedulePeriodicSync();
          },
        );
        FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      }

      if (!kIsWeb) {
        await _safeInit('FCM', () => ref.read(fcmServiceProvider).initialize());
      }

      if (!kIsWeb) {
        await _safeInit('Ads', () => ref.read(adsServiceProvider).initialize());
      }

      AppLogger.info('Rozgar framework initialized successfully');
    } catch (e, st) {
      AppLogger.severe('Framework initialization failed', e, st);
    }

    if (mounted) setState(() => _ready = true);
  }

  Future<void> _safeInit(String name, Future<void> Function() init) async {
    try {
      await init();
    } catch (e, st) {
      AppLogger.warning('$name initialization skipped: $e');
      AppLogger.error('$name stack trace', st);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.work_outline_rounded, size: 64),
                SizedBox(height: 16),
                Text(
                  AppConstants.appName,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 24),
                CircularProgressIndicator(),
              ],
            ),
          ),
        ),
      );
    }

    return const RozgarApp();
  }
}
