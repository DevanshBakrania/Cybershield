import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';

class KeyManager {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const _keyAlias = 'vault_key_final_v3';

  // CHANGE: Return Future<String> NOT Uint8List
  Future<String> getOrGenerateKey() async {
    try {
      String? base64Key = await _storage.read(key: _keyAlias);

      if (base64Key != null) {
        return base64Key;
      }

      final hiveKey = Hive.generateSecureKey();
      final keyBytes = Uint8List.fromList(hiveKey);
      final newKeyString = base64Encode(keyBytes);

      await _storage.write(key: _keyAlias, value: newKeyString);

      return newKeyString;

    } catch (e) {
      // Fallback
      final fallback = Hive.generateSecureKey();
      return base64Encode(Uint8List.fromList(fallback));
    }
  }
}