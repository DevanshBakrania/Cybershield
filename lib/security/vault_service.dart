import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:encrypt/encrypt.dart' as enc;
import '../models/vault_item.dart';

class VaultService {
  static const String _keyStorageName = 'vault_key';
  static const String _boxName = 'secure_vault';
  final _secureStorage = const FlutterSecureStorage();

  late Box<VaultItem> _box;
  late enc.Encrypter _encrypter;
  late enc.IV _iv;

  // Initialize: Check for key, create if missing, open Box
  Future<void> init() async {
    // 1. Get or Generate Encryption Key (32 chars for AES-256)
    String? keyString = await _secureStorage.read(key: _keyStorageName);

    if (keyString == null) {
      keyString = base64Url.encode(enc.Key.fromSecureRandom(32).bytes);
      await _secureStorage.write(key: _keyStorageName, value: keyString);
    }

    final key = enc.Key.fromBase64(keyString);
    _encrypter = enc.Encrypter(enc.AES(key));
    // We use a fixed IV for simplicity in this demo, but random IV is better for prod
    _iv = enc.IV.fromLength(16);

    // 2. Register Adapter
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(VaultItemAdapter());
    }

    // 3. Open the Hive Box
    _box = await Hive.openBox<VaultItem>(_boxName);
  }

  // 🔒 Add Data (Encrypts immediately)
  Future<void> addItem(String title, String rawContent, String category) async {
    final encryptedContent = _encrypter.encrypt(rawContent, iv: _iv).base64;

    final item = VaultItem(
      title: title,
      content: encryptedContent, // Storing garbage text
      category: category,
      createdAt: DateTime.now(),
    );

    await _box.add(item);
  }

  // 🔓 Read Data (Decrypts on the fly)
  List<Map<String, dynamic>> getAllItems() {
    return _box.values.map((item) {
      String decryptedContent;
      try {
        decryptedContent = _encrypter.decrypt64(item.content, iv: _iv);
      } catch (e) {
        decryptedContent = "⚠️ Decryption Error";
      }

      return {
        "key": item.key, // Hive ID
        "title": item.title,
        "content": decryptedContent,
        "category": item.category,
        "date": item.createdAt,
      };
    }).toList();
  }

  // Delete
  Future<void> deleteItem(int key) async {
    await _box.delete(key);
  }
}