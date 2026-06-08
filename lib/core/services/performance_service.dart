import 'package:firebase_performance/firebase_performance.dart';

import '../utils/app_logger.dart';

class PerformanceService {
  PerformanceService({FirebasePerformance? performance})
      : _performance = performance ?? FirebasePerformance.instance;

  final FirebasePerformance _performance;

  Future<T> trace<T>(
    String traceName,
    Future<T> Function() operation, {
    Map<String, String>? attributes,
  }) async {
    final trace = _performance.newTrace(traceName);
    await trace.start();
    attributes?.forEach(trace.putAttribute);

    try {
      final result = await operation();
      trace.putAttribute('status', 'success');
      return result;
    } catch (e, st) {
      trace.putAttribute('status', 'error');
      trace.putAttribute('error', e.toString());
      AppLogger.error('Trace [$traceName] failed', e, st);
      rethrow;
    } finally {
      await trace.stop();
    }
  }

  HttpMetric createHttpMetric(String url, HttpMethod method) =>
      _performance.newHttpMetric(url, method);
}
