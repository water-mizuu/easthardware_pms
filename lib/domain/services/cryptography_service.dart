import 'dart:convert';
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

  /// Generates a coprime number to [n].
  ///   Technically, this generates a prime number.
  static int generateCoprime(int n) {
    final primes = <int>[2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37];

    var increment = 2;
    while (primes.last < sqrt(n)) {
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

  static String encryptAsymmetric(String a, BigInt n, BigInt e) {
    // Split the string into characters.
    // Apply the formula: C = M^e mod n for M in a.

    final chars = utf8.encode(a);
    final encrypted = chars
        .map(BigInt.from) //
        .map((m) => m.modPow(e, n))
        .map((m) => m.toRadixString(36))
        .toList();

    final jsonEncoded = jsonEncode(encrypted);
    final utf8Encoded = utf8.encode(jsonEncoded);
    final base64Encoded = base64.encode(utf8Encoded);

    return base64Encoded;
  }

  static String decryptAsymmetric(String a, BigInt n, BigInt d) {
    final base64Decoded = base64.decode(a);
    final utf8Decoded = utf8.decode(base64Decoded);
    final jsonDecoded = (jsonDecode(utf8Decoded) as List<dynamic>).cast<String>();
    final chars = jsonDecoded //
        .map((c) => BigInt.parse(c, radix: 36)) //
        .map((c) => c.modPow(d, n))
        .map((c) => c.toInt().toInt())
        .toList();
    final string = utf8.decode(chars);

    return string;
  }

  /// Encrypts a string using the ChaCha20 algorithm.
  ///
  /// [a] is the plaintext to encrypt.
  /// [key] is the encryption key as a BigInt.
  /// Returns the Base64-encoded encrypted text with nonce prepended.
  static String encryptSymmetric(String a, BigInt key) {
    // Convert key to 32 bytes (256 bits)
    final keyBytes = _bigIntToUint8List(key, 32);

    // Generate a random nonce (12 bytes for ChaCha20)
    final nonce = generateSalt(12);

    // Convert the input string to bytes
    final plaintext = Uint8List.fromList(utf8.encode(a));

    // Encrypt the plaintext
    final ciphertext = _chacha20(plaintext, keyBytes, nonce);

    // Combine nonce and ciphertext for storage/transmission
    final combined = Uint8List(nonce.length + ciphertext.length)
      ..setAll(0, nonce)
      ..setAll(nonce.length, ciphertext);

    // Return as Base64 string
    return base64.encode(combined);
  }

  /// Decrypts a string using the ChaCha20 algorithm.
  ///
  /// [a] is the Base64-encoded ciphertext with nonce prepended.
  /// [key] is the decryption key as a BigInt (same as the encryption key).
  /// Returns the original plaintext.
  static String decryptSymmetric(String a, BigInt key) {
    // Decode the Base64 string
    final combined = base64.decode(a);

    // Extract nonce (first 12 bytes)
    final nonce = Uint8List(12)..setAll(0, combined.sublist(0, 12));

    // Extract ciphertext (remaining bytes)
    final ciphertext = Uint8List(combined.length - 12)..setAll(0, combined.sublist(12));

    // Convert key to 32 bytes (256 bits)
    final keyBytes = _bigIntToUint8List(key, 32);

    // Decrypt the ciphertext
    final plaintext = _chacha20(ciphertext, keyBytes, nonce);

    // Convert plaintext bytes back to string
    return utf8.decode(plaintext);
  }

  /// Generates two small prime numbers. This is just for basic security.
  static (int, int) generateTwoPrimes() {
    final primes = <int>[2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41];

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

  /// ChaCha20 algorithm implementation.
  ///
  /// This function both encrypts and decrypts (ChaCha20 is symmetric).
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
      state[4 + i] = _bytesToWord(key, i * 4);
    }

    // Initial counter (starts at 0)
    state[12] = 0;

    // Add nonce to state (3 words/12 bytes)
    for (var i = 0; i < 3; i++) {
      state[13 + i] = _bytesToWord(nonce, i * 4);
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
