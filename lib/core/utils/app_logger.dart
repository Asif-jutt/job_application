import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

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
    if (kDebugMode) _logger.d(message, error: data);
  }

  static void info(String message, [dynamic data]) {
    if (kDebugMode) _logger.i(message, error: data);
  }

  static void warning(String message, [dynamic data]) {
    if (kDebugMode) _logger.w(message, error: data);
  }

  static void error(String message, [dynamic error, StackTrace? stackTrace]) {
    if (kDebugMode) _logger.e(message, error: error, stackTrace: stackTrace);
  }

  static void network(String tag, dynamic payload) {
    if (kDebugMode) _logger.d('[$tag] $payload');
  }

  static void severe(String message, Object error, StackTrace stackTrace) {
    if (kDebugMode) {
      _logger.f(message, error: error, stackTrace: stackTrace);
    }
  }
}

/// Strips all logs in release/production builds.
class _ProductionFilter extends LogFilter {
  @override
  bool shouldLog(LogEvent event) => kDebugMode;
}
