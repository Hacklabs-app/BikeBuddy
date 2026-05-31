import 'dart:convert';
import 'package:encrypt/encrypt.dart' as encrypt;

class QrEncryptionHelper {
  // A secure 32-character key for AES-256 symmetric encryption
  static final _key = encrypt.Key.fromUtf8('BikeBuddyAESSecretKeyForRiders32');
  // A secure 16-character initialization vector
  static final _iv = encrypt.IV.fromUtf8('BikeBuddyAES_IV1');

  /// Encrypts rider's core profile details into a secure, URL-safe Base64 string.
  static String encryptRiderPayload({
    required String id,
    required String name,
    required String phone,
  }) {
    final payloadMap = {
      'id': id,
      'name': name,
      'phone': phone,
    };
    final jsonString = jsonEncode(payloadMap);
    final encrypter = encrypt.Encrypter(encrypt.AES(_key, mode: encrypt.AESMode.cbc));
    
    final encrypted = encrypter.encrypt(jsonString, iv: _iv);
    return encrypted.base64;
  }

  /// Decrypts a secure Base64 string back into the rider's core profile details.
  /// Returns null if decryption fails (e.g., invalid QR code format).
  static Map<String, String>? decryptRiderPayload(String encryptedBase64) {
    try {
      final encrypter = encrypt.Encrypter(encrypt.AES(_key, mode: encrypt.AESMode.cbc));
      final decrypted = encrypter.decrypt64(encryptedBase64, iv: _iv);
      
      final Map<String, dynamic> decodedMap = jsonDecode(decrypted);
      return {
        'id': decodedMap['id']?.toString() ?? '',
        'name': decodedMap['name']?.toString() ?? '',
        'phone': decodedMap['phone']?.toString() ?? '',
      };
    } catch (_) {
      // Decryption failed: either scanned a different QR or invalid key/IV
      return null;
    }
  }
}
