import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:encrypt/encrypt.dart' as enc;

class VaultService {
  static const String _keyPrefix = 'vault_key_'; // per user
  final _secureStorage = const FlutterSecureStorage();

  late enc.Encrypter _encrypter;
  late enc.IV _iv;

  /// Initialize encryption for a specific user
  Future<void> init(String username) async {
    final keyName = '$_keyPrefix$username';

    String? keyString = await _secureStorage.read(key: keyName);

    if (keyString == null) {
      keyString = base64Url.encode(enc.Key.fromSecureRandom(32).bytes);
      await _secureStorage.write(key: keyName, value: keyString);
    }

    final key = enc.Key.fromBase64(keyString);
    _encrypter = enc.Encrypter(enc.AES(key));
    _iv = enc.IV.fromLength(16);
  }

  /// Encrypt plain text
  String encrypt(String raw) {
    return _encrypter.encrypt(raw, iv: _iv).base64;
  }

  /// Decrypt encrypted text
  String decrypt(String encrypted) {
    return _encrypter.decrypt64(encrypted, iv: _iv);
  }
}
