import 'package:encrypt/encrypt.dart' as encrypt;

class EncryptionService {
  // WARNING: In a real application, you should never hardcode the key.
  // This key should be securely stored and managed, for example, using a secure storage mechanism
  // and potentially derived from a shared secret between the users in a conversation.
  static final _key = encrypt.Key.fromUtf8('my32lengthsupersecretnooneknows1');
  final _iv = encrypt.IV.fromLength(16); // IV should be unique for each encryption
  final _encrypter = encrypt.Encrypter(encrypt.AES(_key));

  String encryptText(String plainText) {
    // In a real app, you might want to generate a new IV for each message
    // and send it along with the encrypted text. For simplicity here, we use a fixed one.
    final encrypted = _encrypter.encrypt(plainText, iv: _iv);
    return encrypted.base64;
  }

  String decryptText(String encryptedText) {
    try {
      final encryptedData = encrypt.Encrypted.fromBase64(encryptedText);
      final decrypted = _encrypter.decrypt(encryptedData, iv: _iv);
      return decrypted;
    } catch (e) {
      // If decryption fails, it might be an old, unencrypted message.
      // Or it could be a sign of a problem.
      print('Decryption failed: $e');
      return encryptedText; // Return original text if decryption fails
    }
  }
}
