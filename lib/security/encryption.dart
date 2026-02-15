import 'package:encrypt/encrypt.dart' as enc; // Changed name to 'enc' to avoid conflict
import 'dart:convert';

class EncryptionService {
  late enc.Encrypter _encrypter;
  late enc.IV _iv;
  bool _isReady = false;

  /// Initialize with a Base64 Encoded Key String
  void init(String base64Key) {
    try {
      // Decode the string back to bytes for the algorithm
      final keyBytes = base64Decode(base64Key);
      final key = enc.Key(keyBytes);

      _iv = enc.IV.fromLength(16); // Standard AES IV length
      _encrypter = enc.Encrypter(enc.AES(key));
      _isReady = true;
      print("✅ ENCRYPTION SERVICE: Ready");
    } catch (e) {
      print("❌ ENCRYPTION INIT FAILED: $e");
    }
  }

  // Now 'encrypt' is just the method name, no conflict!
  String encrypt(String plainText) {
    if (!_isReady) return plainText;
    final encrypted = _encrypter.encrypt(plainText, iv: _iv);
    // Combine IV and Ciphertext so we can decrypt later
    return "${_iv.base64}:${encrypted.base64}";
  }

  String decrypt(String encryptedFull) {
    if (!_isReady) return "Error: Not Ready";
    try {
      final parts = encryptedFull.split(':');
      if (parts.length != 2) return "Error: Corrupt Data";

      final iv = enc.IV.fromBase64(parts[0]);
      final encryptedText = enc.Encrypted.fromBase64(parts[1]);

      return _encrypter.decrypt(encryptedText, iv: iv);
    } catch (e) {
      print("Decryption Error: $e");
      throw Exception("Decryption Failed");
    }
  }
}