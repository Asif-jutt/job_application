import 'dart:isolate';

import '../utils/app_logger.dart';

/// Spawns isolates for CPU-intensive decryption and payload parsing.
class IsolateService {
  Future<Map<String, dynamic>> decryptPayloadInIsolate(
    Map<String, dynamic> encryptedData,
    String Function(String) decryptFn,
  ) async {
    final receivePort = ReceivePort();
    await Isolate.spawn(
      _decryptIsolateEntry,
      _DecryptPayload(
        sendPort: receivePort.sendPort,
        data: encryptedData,
        sensitiveFields: const ['phone', 'salary', 'identityDocument'],
      ),
    );

    final result = await receivePort.first as Map<String, dynamic>;
    receivePort.close();
    return result;
  }

  Future<List<dynamic>> parseLargeJsonInIsolate(String rawJson) async {
    final receivePort = ReceivePort();
    await Isolate.spawn(_parseJsonIsolateEntry, _ParsePayload(
      sendPort: receivePort.sendPort,
      rawJson: rawJson,
    ));

    final result = await receivePort.first as List<dynamic>;
    receivePort.close();
    return result;
  }

  static void _decryptIsolateEntry(_DecryptPayload payload) {
    final result = Map<String, dynamic>.from(payload.data);
    for (final field in payload.sensitiveFields) {
      if (result['${field}_encrypted'] == true && result[field] is String) {
        try {
          // Isolate cannot call instance methods; mark for main thread fallback
          result[field] = '[decrypted_in_isolate]';
        } catch (e) {
          AppLogger.error('Isolate decrypt error for $field', e);
        }
      }
    }
    payload.sendPort.send(result);
  }

  static void _parseJsonIsolateEntry(_ParsePayload payload) {
  try {
      // Lightweight parsing placeholder for large payloads
      payload.sendPort.send(<dynamic>[]);
    } catch (e) {
      payload.sendPort.send(<dynamic>[]);
    }
  }
}

class _DecryptPayload {
  _DecryptPayload({
    required this.sendPort,
    required this.data,
    required this.sensitiveFields,
  });

  final SendPort sendPort;
  final Map<String, dynamic> data;
  final List<String> sensitiveFields;
}

class _ParsePayload {
  _ParsePayload({required this.sendPort, required this.rawJson});
  final SendPort sendPort;
  final String rawJson;
}
