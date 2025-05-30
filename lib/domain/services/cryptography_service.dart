import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:easthardware_pms/domain/backend/extension_types/secure_keys.dart';
import 'package:easthardware_pms/domain/backend/microservices/key_microservice.dart';
import 'package:flutter/foundation.dart';

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

  /// Generates a key pair according to the RSA algorithm.
  ///   Note: This is not a secure implementation, and only generates small-sized keys.
  static AsymmetricKeys generateKeyPair() {
    final (p, q) = CryptographyService.generateTwoPrimes();
    final n = p * q;
    final phiN = (p - 1) * (q - 1);
    final e = CryptographyService.generatePrimeLessThanRootOf(phiN);
    final d = CryptographyService.generateModularInverse(e, phiN);

    final publicKey = (BigInt.from(n), BigInt.from(e));
    final privateKey = (BigInt.from(n), BigInt.from(d));

    return (publicKey, privateKey);
  }

  /// Generates a coprime number to [n].
  ///   Technically, this generates a prime number.
  static int generatePrimeLessThanRootOf(int n) {
    final primes = _primeBasis.toList(growable: true);
    final root = pow(n, 0.5).toInt();

    var increment = 2;
    while (primes.last < root) {
      final candidate = primes.last + increment;

      if (primes.any((p) => candidate % p == 0)) {
        increment += 2;
      } else {
        primes.add(candidate);
        increment = 2;
      }
    }
    final decrement = Random.secure().nextInt(9) + 1;
    final candidate = primes[primes.length - decrement];
    assert(candidate < n);

    return candidate;
  }

  /// Gets the modular inverse of an integer [a] mod [p].
  static int generateModularInverse(int a, int p) {
    var (t, newT) = (0, 1);
    var (r, newR) = (p, a);

    while (newR != 0) {
      final quotient = r ~/ newR;

      (r, newR) = (newR, r - quotient * newR);
      (t, newT) = (newT, t - quotient * newT);
    }

    if (r > 1) {
      throw ArgumentError('a and p are not coprime');
    }

    if (t < 0) {
      t += p;
    }

    return t;
  }

  /// Encrypts a string using an RSA-based asymmetric encryption scheme.
  /// Returns the Base64-encoded string containing the encrypted data and integrity hash.
  static String encryptAsymmetric(String plaintext, AsymmetricKey publicKey) {
    final (n, e) = publicKey;

    // Convert the input string to UTF-8 bytes.
    final utf8PlaintextBytes = utf8.encode(plaintext);

    // Encrypt each byte individually using RSA and convert to base-36 string.
    final encryptedByteStrings = utf8PlaintextBytes
        .map(BigInt.from) // Convert byte to BigInt
        .map((m) => m.modPow(e, n)) // RSA encryption operation
        .map((m) => m.toRadixString(36)) // Convert encrypted BigInt to base-36 string
        .toList();

    // Encode the list of encrypted byte strings as a JSON string.
    // This provides a structured way to represent the list of strings.
    final jsonEncodedEncryptedData = jsonEncode(encryptedByteStrings);

    // Convert the JSON string to UTF-8 bytes.
    final utf8JsonBytes = utf8.encode(jsonEncodedEncryptedData);

    // Calculate an integrity hash (SHA-256) of the UTF-8 encoded JSON data.
    final integrityHash = sha256.convert(utf8JsonBytes).bytes;

    // Combine the UTF-8 JSON bytes and the integrity hash.
    final outputBytes = Uint8List(utf8JsonBytes.length + integrityHash.length)
      ..setAll(0, utf8JsonBytes)
      ..setAll(utf8JsonBytes.length, integrityHash);

    // Encode the combined bytes as a Base64 string for transmission/storage.
    final base64EncodedOutput = base64.encode(outputBytes);

    return base64EncodedOutput;
  }

  /// Decrypts a string that was encrypted using the custom RSA-based asymmetric scheme.
  /// Returns the original plaintext string if decryption and integrity check are successful.
  /// Throws an ArgumentError if the integrity check fails or the input format is invalid.
  static String decryptAsymmetric(String base64Ciphertext, AsymmetricKey encryptionKey) {
    final (n, d) = encryptionKey;
    final inputBytes = base64.decode(base64Ciphertext);

    // Define the length of the SHA-256 hash (32 bytes).
    const hashLength = 32;
    if (inputBytes.length < hashLength) {
      throw ArgumentError('Invalid input: too short to contain data and integrity hash.');
    }

    // Separate the UTF-8 encoded JSON data from the appended integrity hash.
    final utf8JsonBytes = inputBytes.sublist(0, inputBytes.length - hashLength);
    final receivedIntegrityHash = inputBytes.sublist(inputBytes.length - hashLength);

    // Calculate the expected integrity hash of the received UTF-8 JSON data.
    final calculatedIntegrityHash = sha256.convert(utf8JsonBytes).bytes;

    // Verify the integrity of the data using a constant-time comparison.
    if (!_ChaCha20Poly1305._constantTimeEquals(
      receivedIntegrityHash,
      Uint8List.fromList(calculatedIntegrityHash),
    )) {
      throw ArgumentError('Invalid integrity hash: Data may have been tampered with.');
    }

    // Decode the UTF-8 JSON string back to a list of strings.
    final jsonDecodedEncryptedData = utf8.decode(utf8JsonBytes);
    final encryptedBytes = (jsonDecode(jsonDecodedEncryptedData) as List<dynamic>).cast<String>();

    // Decrypt each base-36 string representation of an encrypted byte.
    final decryptedBytes = encryptedBytes
        .map((s) => BigInt.parse(s, radix: 36)) // Convert base-36 string to BigInt
        .map((c) => c.modPow(d, n)) // RSA decryption operation
        .map((c) => c.toInt()) // Convert decrypted BigInt to int (byte value)
        .toList();

    // Convert the list of decrypted bytes back to a string using UTF-8 decoding.
    return utf8.decode(decryptedBytes);
  }

  /// Generates two small prime numbers. This is just for basic security.
  static (int, int) generateTwoPrimes() {
    final primes = _primeBasis.toList(growable: true);

    var increment = 2;

    final initialCount = Random().nextInt(5000) + 500;
    while (primes.length < initialCount) {
      final candidate = primes.last + increment;

      if (primes.any((p) => candidate % p == 0)) {
        increment += 2;
      } else {
        primes.add(candidate);
        increment = 2;
      }
    }

    final firstPrime = primes.last;
    final count = primes.length;
    final additional = Random().nextInt(5000) + 500;
    while (primes.length < count + additional) {
      final candidate = primes.last + increment;

      if (primes.any((p) => candidate % p == 0)) {
        increment += 2;
      } else {
        primes.add(candidate);
        increment = 2;
      }
    }

    final secondPrime = primes.last;
    if (Random().nextDouble() < 0.5) {
      return (secondPrime, firstPrime);
    }

    return (firstPrime, secondPrime);
  }

  /// Encrypts a string using ChaCha20-Poly1305 authenticated encryption.
  /// Returns the Base64-encoded authenticated encrypted text (nonce + ciphertext + tag).
  static String encryptSymmetric(String plaintext, EncryptionKey key) {
    final keyBytes = _ChaCha20Poly1305._bigIntToUint8List(key.key, 32);
    final nonce = generateSalt(12);
    final plaintextBytes = utf8.encode(plaintext);

    // Additional Authenticated Data (AAD).
    // For this implementation, AAD is empty. If AAD were used,
    // it would be included in the Poly1305 MAC calculation but not encrypted.
    final aad = Uint8List(0);

    // Encrypt the plaintext using ChaCha20.
    final ciphertext = _ChaCha20Poly1305._chacha20(plaintextBytes, keyBytes, nonce);

    // Generate the Poly1305 authentication tag.
    // First, derive a one-time Poly1305 key from the main ChaCha20 key and the nonce.
    final poly1305Key = _ChaCha20Poly1305._deriveAuthKey(keyBytes, nonce);

    // Prepare the data for Poly1305 MAC calculation according to RFC 8439:
    final dataToAuthenticate = _ChaCha20Poly1305._prepareAuthData(aad, ciphertext);

    // Calculate the authentication tag (MAC).
    final tag = _ChaCha20Poly1305._poly1305Mac(dataToAuthenticate, poly1305Key);

    // Combine nonce, ciphertext, and tag into a single byte array for transmission/storage.
    final combinedOutput = Uint8List(nonce.length + ciphertext.length + tag.length)
      ..setAll(0, nonce)
      ..setAll(nonce.length, ciphertext)
      ..setAll(nonce.length + ciphertext.length, tag);

    // Return the combined data as a Base64 encoded string.
    return base64.encode(combinedOutput);
  }

  /// Decrypts a string using ChaCha20-Poly1305 authenticated encryption.
  /// Returns the original plaintext if authentication passes.
  /// Throws an ArgumentError if authentication fails or the data format is invalid.
  static String decryptSymmetric(String base64CiphertextWithAuth, EncryptionKey key) {
    // Decode the Base64 input string.
    final Uint8List combinedInput;
    try {
      combinedInput = base64.decode(base64CiphertextWithAuth);
    } catch (e) {
      throw ArgumentError('Invalid Base64 input for symmetric decryption.');
    }

    const nonceLength = 12;
    const tagLength = 16;
    const minPayloadLength = nonceLength + tagLength; // Minimum length for nonce and tag.

    // Ensure the combined data is long enough to contain at least the nonce and tag.
    if (combinedInput.length < minPayloadLength) {
      throw ArgumentError('Invalid encrypted data format: too short to contain nonce and tag.');
    }

    // Extract the nonce (first 12 bytes).
    final nonce = Uint8List(nonceLength)..setAll(0, combinedInput.sublist(0, nonceLength));

    // Extract the authentication tag (last 16 bytes).
    final receivedTag = Uint8List(tagLength)
      ..setAll(0, combinedInput.sublist(combinedInput.length - tagLength));

    // Extract the ciphertext (data between nonce and tag).
    final ciphertextLength = combinedInput.length - nonceLength - tagLength;
    if (ciphertextLength < 0) {
      // Should ideally be caught by minPayloadLength check.
      throw ArgumentError(
        'Invalid encrypted data format: inconsistent lengths '
        'leading to negative ciphertext length.',
      );
    }
    final ciphertext = Uint8List(ciphertextLength)
      ..setAll(0, combinedInput.sublist(nonceLength, combinedInput.length - tagLength));

    // Convert the EncryptionKey to a 32-byte Uint8List.
    final keyBytes = _ChaCha20Poly1305._bigIntToUint8List(key.key, 32);

    // AAD must be the same as used during encryption (empty in this implementation).
    final aad = Uint8List(0);

    // Derive the Poly1305 authentication key using the main ChaCha20 key and the nonce.
    final poly1305Key = _ChaCha20Poly1305._deriveAuthKey(keyBytes, nonce);

    // Prepare the data for Poly1305 MAC verification.
    final dataToVerify = _ChaCha20Poly1305._prepareAuthData(aad, ciphertext);

    // Calculate the expected authentication tag based on the received data.
    final calculatedTag = _ChaCha20Poly1305._poly1305Mac(dataToVerify, poly1305Key);

    // Verify that the calculated tag matches the received tag using a constant-time comparison
    // to prevent timing attacks.
    if (!_ChaCha20Poly1305._constantTimeEquals(calculatedTag, receivedTag)) {
      throw ArgumentError(
        'Authentication failed: Data may have been '
        'tampered with or key is incorrect.',
      );
    }

    // If authentication passed, decrypt the ciphertext using ChaCha20.
    final plaintextBytes = _ChaCha20Poly1305._chacha20(ciphertext, keyBytes, nonce);

    // Convert the decrypted plaintext bytes back to a UTF-8 string.
    return utf8.decode(plaintextBytes);
  }

  static const _primeBasis = [
    ...[2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41],
    ...[43, 47, 53, 59, 61, 67, 71, 73, 79, 83, 89, 97],
    ...[101, 103, 107, 109, 113, 127, 131, 137, 139, 149],
    ...[151, 157, 163, 167, 173, 179, 181, 191, 193, 197],
  ];
}

extension CryptographyServiceExtension on String {
  String encryptSymmetric(EncryptionKey encryptionKey) {
    return CryptographyService.encryptSymmetric(this, encryptionKey);
  }

  String decryptSymmetric(EncryptionKey encryptionKey) {
    return CryptographyService.decryptSymmetric(this, encryptionKey);
  }

  String encryptAsymmetric(AsymmetricKey encryptionKey) {
    return CryptographyService.encryptAsymmetric(this, encryptionKey);
  }

  String decryptAsymmetric(AsymmetricKey encryptionKey) {
    return CryptographyService.decryptAsymmetric(this, encryptionKey);
  }
}

class _ChaCha20Poly1305 {
  /// ChaCha20 encryption/decryption algorithm.
  ///
  /// ChaCha20 is a symmetric cipher, so the same function is used for both encryption and decryption.
  /// [data] is the data to encrypt or decrypt.
  /// [key] is the 32-byte key.
  /// [nonce] is the 12-byte nonce.
  /// Returns the encrypted or decrypted data.
  static Uint8List _chacha20(Uint8List data, Uint8List key, Uint8List nonce) {
    // Ensure key is 32 bytes (256 bits)
    if (key.length != 32) {
      throw ArgumentError('ChaCha20 requires a 32-byte key');
    }

    // Ensure nonce is 12 bytes
    if (nonce.length != 12) {
      throw ArgumentError('ChaCha20 requires a 12-byte nonce');
    }

    // Initialize the state
    final state = _initState(key, nonce);

    // Result buffer
    final result = Uint8List(data.length);

    // Process data in 64-byte blocks
    var counter = 0;
    for (var i = 0; i < data.length; i += 64) {
      // Generate keystream block
      final keyStream = _generateKeyStream(state, counter++);

      // XOR with data (as many bytes as we have left)
      final bytesToProcess = min(64, data.length - i);
      for (var j = 0; j < bytesToProcess; j++) {
        result[i + j] = data[i + j] ^ keyStream[j];
      }
    }

    return result;
  }

  /// Derives a one-time key for Poly1305 from the main key and nonce.
  /// This follows the ChaCha20-Poly1305 construction where the first 32 bytes
  /// of the keystream (with counter 0) are used as the Poly1305 key.
  static Uint8List _deriveAuthKey(Uint8List key, Uint8List nonce) {
    // Initialize the state
    final state = _initState(key, nonce);

    // Generate keystream block with counter 0
    final keyStream = _generateKeyStream(state, 0);

    // Return the first 32 bytes of the keystream
    return keyStream.sublist(0, 32);
  }

  /// Prepares data for Poly1305 authentication.
  /// Follows the RFC 8439 format for ChaCha20-Poly1305:
  /// AAD padded to 16 bytes + ciphertext padded to 16 bytes +
  /// 8-byte AAD length + 8-byte ciphertext length (both little endian)
  static Uint8List _prepareAuthData(Uint8List aad, Uint8List ciphertext) {
    // Calculate the padded lengths
    final aadPaddedLen = (aad.length + 15) & ~15; // Round up to multiple of 16
    final ciphertextPaddedLen = (ciphertext.length + 15) & ~15; // Round up to multiple of 16

    // Prepare the result buffer: AAD + padding + ciphertext + padding + length block
    final result = Uint8List(aadPaddedLen + ciphertextPaddedLen + 16);

    // Copy AAD
    result.setAll(0, aad);

    // Copy ciphertext (after padded AAD)
    result.setAll(aadPaddedLen, ciphertext);

    // Set the AAD length in little-endian (8 bytes)
    _setLittleEndianInt64(result, aadPaddedLen + ciphertextPaddedLen, aad.length);

    // Set the ciphertext length in little-endian (8 bytes)
    _setLittleEndianInt64(result, aadPaddedLen + ciphertextPaddedLen + 8, ciphertext.length);

    return result;
  }

  /// Sets an 8-byte little-endian representation of a 64-bit integer in a buffer.
  static void _setLittleEndianInt64(Uint8List buffer, int offset, int value) {
    buffer[offset] = value & 0xFF;
    buffer[offset + 1] = (value >> 8) & 0xFF;
    buffer[offset + 2] = (value >> 16) & 0xFF;
    buffer[offset + 3] = (value >> 24) & 0xFF;
    buffer[offset + 4] = (value >> 32) & 0xFF;
    buffer[offset + 5] = (value >> 40) & 0xFF;
    buffer[offset + 6] = (value >> 48) & 0xFF;
    buffer[offset + 7] = (value >> 56) & 0xFF;
  }

  /// Poly1305 Message Authentication Code algorithm.
  ///
  /// Implements the Poly1305 MAC algorithm as specified in RFC 8439.
  /// [message] is the message to authenticate.
  /// [key] is the 32-byte one-time key.
  /// Returns a 16-byte authentication tag.
  static Uint8List _poly1305Mac(Uint8List message, Uint8List key) {
    if (key.length != 32) {
      throw ArgumentError('Poly1305 requires a 32-byte key');
    }

    // Extract r and s from key
    // r is first 16 bytes with specific bits cleared
    final r = _createPoly1305ClampedR(key.sublist(0, 16));

    // s is the last 16 bytes
    final s = _littleEndianToInt128(key.sublist(16, 32));

    // Initialize accumulator
    var acc = BigInt.zero;

    // Poly1305 prime: 2^130 - 5
    final p = (BigInt.one << 130) - BigInt.from(5);

    // Process message in 16-byte blocks
    for (var i = 0; i < message.length; i += 16) {
      // Determine block size (could be less than 16 for the last block)
      final blockSize = min(16, message.length - i);

      // Extract the current block
      final block = message.sublist(i, i + blockSize);

      // Convert block to integer (little endian) and add 1 byte (0x01) at the end
      var n = _littleEndianToInt(block);
      if (blockSize < 16) {
        n += BigInt.one << (8 * blockSize);
      }

      // Update accumulator: (acc + n) * r % p
      acc = (acc + n) * r % p;
    }

    // Final step: add s to acc
    acc = (acc + s) & ((BigInt.one << 128) - BigInt.one);

    // Convert to bytes (16 bytes output)
    return _int128ToLittleEndian(acc);
  }

  /// Creates the clamped r value for Poly1305 by applying bit masks.
  /// r &= 0x0ffffffc0ffffffc0ffffffc0fffffff
  static BigInt _createPoly1305ClampedR(Uint8List r) {
    final clampedR = Uint8List.fromList(r);

    // Apply bit masks according to RFC 8439
    clampedR[3] &= 15; // Clear the top four bits of r[3]
    clampedR[7] &= 15; // Clear the top four bits of r[7]
    clampedR[11] &= 15; // Clear the top four bits of r[11]
    clampedR[15] &= 15; // Clear the top four bits of r[15]
    clampedR[4] &= 252; // Clear the bottom two bits of r[4]
    clampedR[8] &= 252; // Clear the bottom two bits of r[8]
    clampedR[12] &= 252; // Clear the bottom two bits of r[12]

    return _littleEndianToInt(clampedR);
  }

  /// Converts a byte array to a BigInt (little-endian).
  static BigInt _littleEndianToInt(Uint8List bytes) {
    var result = BigInt.zero;
    for (var i = bytes.length - 1; i >= 0; i--) {
      result = (result << 8) | BigInt.from(bytes[i]);
    }
    return result;
  }

  /// Special case for 128-bit integer conversion from little-endian.
  static BigInt _littleEndianToInt128(Uint8List bytes) {
    var result = BigInt.zero;
    for (var i = 0; i < bytes.length; i++) {
      result |= BigInt.from(bytes[i]) << (8 * i);
    }
    return result;
  }

  /// Converts a 128-bit BigInt to a 16-byte array (little-endian).
  static Uint8List _int128ToLittleEndian(BigInt value) {
    final result = Uint8List(16);
    for (var i = 0; i < 16; i++) {
      result[i] = (value >> (8 * i)).toInt() & 0xFF;
    }
    return result;
  }

  /// Constant-time comparison of two byte arrays to prevent timing attacks.
  /// Returns true if the two arrays are equal, false otherwise.
  static bool _constantTimeEquals(Uint8List a, Uint8List b) {
    if (a.length != b.length) return false;

    var result = 0;
    for (var i = 0; i < a.length; i++) {
      // XOR all bytes, the result will be 0 only if all bytes match
      result |= a[i] ^ b[i];
    }

    return result == 0;
  }

  /// Converts a BigInt to a Uint8List of specified length in bytes.
  ///
  /// [value] The BigInt to convert
  /// [length] The desired length of the resulting Uint8List in bytes
  /// Returns a Uint8List representing the BigInt value
  static Uint8List _bigIntToUint8List(BigInt value, int length) {
    final result = Uint8List(length);
    var tempValue = value;

    // Fill from least significant byte to most significant
    for (var i = length - 1; i >= 0; i--) {
      result[i] = (tempValue & BigInt.from(0xFF)).toInt();
      tempValue = tempValue >> 8;
    }

    return result;
  }

  /// Initialize the ChaCha20 state with key and nonce.
  static List<int> _initState(Uint8List key, Uint8List nonce) {
    // ChaCha20 constant: "expand 32-byte k"
    final state = <int>[
      0x61707865, 0x3320646e, 0x79622d32, 0x6b206574, // Constants
      0, 0, 0, 0, 0, 0, 0, 0, // Key (will be filled)
      0, 0, 0, 0 // Counter and nonce (will be filled)
    ];

    // Add key to state (8 words/32 bytes)
    for (var i = 0; i < 8; i++) {
      state[i + 4] = _bytesToWord(key, i * 4);
    }

    // Initial counter (starts at 0)
    state[12] = 0;

    // Add nonce to state (3 words/12 bytes)
    for (var i = 0; i < 3; i++) {
      state[i + 13] = _bytesToWord(nonce, i * 4);
    }

    return state;
  }

  /// Convert 4 bytes to a 32-bit word (little-endian).
  static int _bytesToWord(Uint8List bytes, int offset) {
    return bytes[offset] |
        (bytes[offset + 1] << 8) |
        (bytes[offset + 2] << 16) |
        (bytes[offset + 3] << 24);
  }

  /// Generate key stream block from ChaCha20 state.
  static Uint8List _generateKeyStream(List<int> initialState, int counter) {
    // Create working state
    final workingState = List<int>.from(initialState);

    // Set counter
    workingState[12] = counter;

    // 20 rounds (10 column rounds, 10 diagonal rounds)
    final state = List<int>.from(workingState);
    for (var i = 0; i < 10; i++) {
      // Column round
      _quarterRound(state, 0, 4, 8, 12);
      _quarterRound(state, 1, 5, 9, 13);
      _quarterRound(state, 2, 6, 10, 14);
      _quarterRound(state, 3, 7, 11, 15);

      // Diagonal round
      _quarterRound(state, 0, 5, 10, 15);
      _quarterRound(state, 1, 6, 11, 12);
      _quarterRound(state, 2, 7, 8, 13);
      _quarterRound(state, 3, 4, 9, 14);
    }

    // Add initial state to result
    for (var i = 0; i < 16; i++) {
      state[i] = (state[i] + workingState[i]) & 0xFFFFFFFF;
    }

    // Convert state to bytes
    final keyStream = Uint8List(64);
    for (var i = 0; i < 16; i++) {
      keyStream[i * 4] = state[i] & 0xFF;
      keyStream[i * 4 + 1] = (state[i] >> 8) & 0xFF;
      keyStream[i * 4 + 2] = (state[i] >> 16) & 0xFF;
      keyStream[i * 4 + 3] = (state[i] >> 24) & 0xFF;
    }

    return keyStream;
  }

  /// ChaCha20 quarter round function.
  /// Each round applies a sequence of operations to the state:
  /// a += b; d ^= a; d <<<= 16;
  /// c += d; b ^= c; b <<<= 12;
  /// a += b; d ^= a; d <<<= 8;
  /// c += d; b ^= c; b <<<= 7;
  static void _quarterRound(List<int> state, int a, int b, int c, int d) {
    state[a] = (state[a] + state[b]) & 0xFFFFFFFF;
    state[d] = _rotateLeft(state[d] ^ state[a], 16);

    state[c] = (state[c] + state[d]) & 0xFFFFFFFF;
    state[b] = _rotateLeft(state[b] ^ state[c], 12);

    state[a] = (state[a] + state[b]) & 0xFFFFFFFF;
    state[d] = _rotateLeft(state[d] ^ state[a], 8);

    state[c] = (state[c] + state[d]) & 0xFFFFFFFF;
    state[b] = _rotateLeft(state[b] ^ state[c], 7);
  }

  /// Rotate a 32-bit integer left by [count] bits.
  static int _rotateLeft(int value, int count) {
    return ((value << count) | (value >> (32 - count))) & 0xFFFFFFFF;
  }
}

extension StringWrapExtension on String {
  String get wrap {
    final buffer = StringBuffer();
    for (var i = 0; i < length; i++) {
      if (i > 0 && i % 80 == 0) {
        buffer.writeln();
      }
      buffer.write(this[i]);
    }
    return buffer.toString();
  }

  String get indent {
    final lines = split('\n');
    final indentedLines = lines.map((line) => '  $line').join('\n');

    return indentedLines;
  }

  String get dedent {
    final lines = trimLeft().split('\n');
    final commonDedent = lines
        .skip(1)
        .where((l) => l.trim().isNotEmpty)
        .map((l) => l.length as num)
        .fold(double.infinity, min);

    if (commonDedent.isInfinite) {
      return this;
    }

    return lines //
        .map((l) => l.trim().isEmpty ? l : l.substring(commonDedent.toInt()))
        .join('\n');
  }
}
