import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../utils/app_logger.dart';

class LocalNotificationService {
  LocalNotificationService()
      : _plugin = FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;

  static const String _messagesChannelId = 'rozgar_messages';
  static const String _messagesChannelName = 'Rozgar Messages';
  static const String _appsChannelId = 'rozgar_applications';
  static const String _appsChannelName = 'Job Applications';

  Future<void> initialize() async {
    if (_initialized) return;

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    await android?.createNotificationChannel(
      const AndroidNotificationChannel(
        _messagesChannelId,
        _messagesChannelName,
        importance: Importance.high,
      ),
    );

    await android?.createNotificationChannel(
      const AndroidNotificationChannel(
        _appsChannelId,
        _appsChannelName,
        importance: Importance.high,
        description: 'Application status updates',
      ),
    );

    await android?.requestNotificationsPermission();

    _initialized = true;
    AppLogger.info('Local notifications initialized');
  }

  Future<void> showMessageNotification({
    required String title,
    required String body,
    String? payload,
  }) =>
      _show(
        title: title,
        body: body,
        payload: payload,
        channelId: _messagesChannelId,
        channelName: _messagesChannelName,
      );

  Future<void> showApplicationNotification({
    required String title,
    required String body,
    String? payload,
  }) =>
      _show(
        title: title,
        body: body,
        payload: payload,
        channelId: _appsChannelId,
        channelName: _appsChannelName,
      );

  Future<void> _show({
    required String title,
    required String body,
    String? payload,
    required String channelId,
    required String channelName,
  }) async {
    if (!_initialized) await initialize();

    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelName,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          styleInformation: BigTextStyleInformation(body),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: payload,
    );
    AppLogger.info('Local notification shown: $title');
  }

  void _onNotificationTap(NotificationResponse response) {
    AppLogger.info('Notification tapped: ${response.payload}');
  }
}
