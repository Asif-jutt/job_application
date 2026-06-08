import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  SecureStorageService({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            );

  final FlutterSecureStorage _storage;

  static const String _aesKeyKey = 'rozgar_aes_key';
  static const String _aesIvKey = 'rozgar_aes_iv';

  Future<String?> read(String key) => _storage.read(key: key);

  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  Future<String?> getAesKey() => read(_aesKeyKey);
  Future<String?> getAesIv() => read(_aesIvKey);

  Future<void> saveAesKey(String key) => write(_aesKeyKey, key);
  Future<void> saveAesIv(String iv) => write(_aesIvKey, iv);

  Future<void> clearAll() => _storage.deleteAll();
}
