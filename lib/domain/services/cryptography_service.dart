import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

class CryptographyService {
  const CryptographyService();

  // Generates a secure random salt
  static Uint8List generateSalt([int length = 16]) {
    final secureRandom = Random.secure();
    final salt = Uint8List(length);
    for (var i = 0; i < length; i++) {
      salt[i] = secureRandom.nextInt(256);
    }
    return salt;
  }

  // Hashes password + salt using SHA-256
  static Uint8List generateHash(String password, Uint8List salt) {
    final passwordBytes = Uint8List.fromList(password.codeUnits);
    final combined = Uint8List(salt.length + passwordBytes.length)
      ..setAll(0, salt)
      ..setAll(salt.length, passwordBytes);

    final digest = sha256.convert(combined);
    return Uint8List.fromList(digest.bytes);
  }
}
