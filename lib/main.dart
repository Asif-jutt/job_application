import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/providers/core_providers.dart';
import 'core/services/fcm_service.dart';
import 'core/utils/app_logger.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await _initializeFramework();

  runApp(
    const ProviderScope(
      child: RozgarApp(),
    ),
  );
}

Future<void> _initializeFramework() async {
  AppLogger.info('Initializing Rozgar framework...');

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final container = ProviderContainer();

  try {
    await container.read(aesEncryptionProvider).initialize();

    if (!kIsWeb) {
      await container.read(localNotificationProvider).initialize();
      await container.read(workmanagerServiceProvider).initialize();
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    }

    await _safeInit('FCM', () => container.read(fcmServiceProvider).initialize());

    if (!kIsWeb) {
      await _safeInit('Ads', () => container.read(adsServiceProvider).initialize());
    }

    AppLogger.info('Rozgar framework initialized successfully');
  } catch (e, st) {
    AppLogger.severe('Framework initialization failed', e, st);
  } finally {
    container.dispose();
  }
}

Future<void> _safeInit(String name, Future<void> Function() init) async {
  try {
    await init();
  } catch (e, st) {
    AppLogger.warning('$name initialization skipped', e);
    AppLogger.debug('$name init stack', st);
  }
}
