import 'dart:convert';
import 'dart:math';

import 'package:encrypt/encrypt.dart' as enc;

import '../utils/app_logger.dart';
import 'secure_storage_service.dart';

/// AES-256 CTR encryption for sensitive PII before Firestore writes.
class AesEncryptionService {
  AesEncryptionService(this._secureStorage);

  final SecureStorageService _secureStorage;
  enc.Encrypter? _encrypter;
  enc.IV? _iv;

  Future<void> initialize() async {
    var keyStr = await _secureStorage.getAesKey();
    var ivStr = await _secureStorage.getAesIv();

    if (keyStr == null || ivStr == null) {
      final random = Random.secure();
      keyStr = base64Url.encode(List.generate(32, (_) => random.nextInt(256)));
      ivStr = base64Url.encode(List.generate(16, (_) => random.nextInt(256)));
      await _secureStorage.saveAesKey(keyStr);
      await _secureStorage.saveAesIv(ivStr);
    }

    final key = enc.Key(base64Url.decode(keyStr));
    _iv = enc.IV(base64Url.decode(ivStr));
    _encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.ctr));
    AppLogger.info('AES-256 CTR encryption service initialized');
  }

  String encrypt(String plainText) {
    _ensureReady();
    final encrypted = _encrypter!.encrypt(plainText, iv: _iv!);
    return encrypted.base64;
  }

  String decrypt(String cipherText) {
    _ensureReady();
    return _encrypter!.decrypt64(cipherText, iv: _iv!);
  }

  Map<String, dynamic> encryptFields(
    Map<String, dynamic> data,
    List<String> sensitiveFields,
  ) {
    final result = Map<String, dynamic>.from(data);
    for (final field in sensitiveFields) {
      final value = result[field];
      if (value != null && value is String && value.isNotEmpty) {
        result[field] = encrypt(value);
        result['${field}_encrypted'] = true;
      }
    }
    return result;
  }

  Map<String, dynamic> decryptFields(
    Map<String, dynamic> data,
    List<String> sensitiveFields,
  ) {
    final result = Map<String, dynamic>.from(data);
    for (final field in sensitiveFields) {
      if (result['${field}_encrypted'] == true && result[field] is String) {
        try {
          result[field] = decrypt(result[field] as String);
        } catch (e, st) {
          AppLogger.severe('Decryption failed for $field', e, st);
        }
        result.remove('${field}_encrypted');
      }
    }
    return result;
  }

  void _ensureReady() {
    if (_encrypter == null || _iv == null) {
      throw StateError('AesEncryptionService not initialized. Call initialize() first.');
    }
  }
}
