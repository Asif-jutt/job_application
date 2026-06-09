import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

import 'debug_log_store.dart';

class AppLogger {
  AppLogger._();

  static final Logger _logger = Logger(
    filter: _ProductionFilter(),
    printer: PrettyPrinter(
      methodCount: 2,
      errorMethodCount: 8,
      lineLength: 100,
      colors: true,
      printEmojis: true,
    ),
  );

  static void debug(String message, [dynamic data]) {
    _store('DEBUG', message, data);
    if (kDebugMode) _logger.d(message, error: data);
  }

  static void info(String message, [dynamic data]) {
    _store('INFO', message, data);
    if (kDebugMode) _logger.i(message, error: data);
  }

  static void warning(String message, [dynamic data]) {
    _store('WARN', message, data);
    if (kDebugMode) _logger.w(message, error: data);
  }

  static void error(String message, [dynamic error, StackTrace? stackTrace]) {
    _store('ERROR', message, error);
    if (kDebugMode) _logger.e(message, error: error, stackTrace: stackTrace);
  }

  static void network(String tag, dynamic payload) {
    _store('NETWORK', '[$tag] $payload', null, tag: tag);
    if (kDebugMode) _logger.d('[$tag] $payload');
  }

  static void severe(String message, Object error, StackTrace stackTrace) {
    _store('SEVERE', message, error);
    if (kDebugMode) {
      _logger.f(message, error: error, stackTrace: stackTrace);
    }
  }

  static void auth(String message, [dynamic data]) {
    _store('AUTH', message, data, tag: 'Auth');
    if (kDebugMode) _logger.i('[Auth] $message', error: data);
  }

  static void _store(String level, String message, dynamic data, {String? tag}) {
    final detail = data != null ? '$message | $data' : message;
    DebugLogStore.instance.add(LogEntry(
      level: level,
      message: detail,
      timestamp: DateTime.now(),
      tag: tag,
    ));
  }
}

/// Strips all logs in release/production builds.
class _ProductionFilter extends LogFilter {
  @override
  bool shouldLog(LogEvent event) => kDebugMode;
}
