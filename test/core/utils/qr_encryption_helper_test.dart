import 'package:flutter_test/flutter_test.dart';
import 'package:bike_buddy/core/utils/qr_encryption_helper.dart';

void main() {
  group('QrEncryptionHelper Tests', () {
    const userId = '7710fc76-dd6e-486d-af7b-dfda0b93c4c1';
    const userName = 'John Doe';
    const userPhone = '+254712345678';

    test('Should encrypt and decrypt correctly', () {
      final encrypted = QrEncryptionHelper.encryptRiderPayload(
        id: userId,
        name: userName,
        phone: userPhone,
      );

      expect(encrypted, isNotEmpty);
      expect(encrypted, isNot(contains(userName))); // Make sure plaintext name is not in base64 string

      final decrypted = QrEncryptionHelper.decryptRiderPayload(encrypted);

      expect(decrypted, isNotNull);
      expect(decrypted!['id'], userId);
      expect(decrypted['name'], userName);
      expect(decrypted['phone'], userPhone);
    });

    test('Should return null for invalid encrypted string', () {
      final decrypted = QrEncryptionHelper.decryptRiderPayload('invalid_base64_string');
      expect(decrypted, isNull);
    });
  });
}
