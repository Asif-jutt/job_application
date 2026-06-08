import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../utils/app_logger.dart';
import 'local_notification_service.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  AppLogger.info('FCM background message: ${message.messageId}');
}

class FcmService {
  FcmService({
    FirebaseMessaging? messaging,
    LocalNotificationService? localNotifications,
  })  : _messaging = messaging ?? FirebaseMessaging.instance,
        _localNotifications =
            localNotifications ?? LocalNotificationService();

  final FirebaseMessaging _messaging;
  final LocalNotificationService _localNotifications;

  Future<void> initialize() async {
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (!kIsWeb) {
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    }

    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpened);

    if (kIsWeb) {
      // Required for web: points to web/firebase-messaging-sw.js
      await _messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    }

    final token = await _messaging.getToken();
    AppLogger.info('FCM token: $token');
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    AppLogger.info('FCM foreground: ${message.notification?.title}');
    final notification = message.notification;
    if (notification != null) {
      await _localNotifications.showMessageNotification(
        title: notification.title ?? 'Rozgar',
        body: notification.body ?? '',
        payload: message.data['chatId'] as String?,
      );
    }
  }

  void _handleMessageOpened(RemoteMessage message) {
    AppLogger.info('FCM opened app: ${message.data}');
  }

  Future<String?> getToken() => _messaging.getToken();
}
