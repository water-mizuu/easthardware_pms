import 'package:easthardware_pms/domain/backend/extension_types/secure_keys.dart';

/// A handshake connection is a temporary connection that is used to establish
///   a secure connection between the client and the server.
///
/// It is a multi-step process that involves the client and the server exchanging
///   random values, public keys, and encrypted pre-master secrets. Once the handshake
///   is complete, a secure connection is established that can be used for end-to-end encryption.
/// The handshake connection is valid for a limited time, after which it is removed.
class HandshakeConnection {
  HandshakeConnection({
    required this.limit,
    required this.step,
    required this.isPersistent,
  });

  final bool isPersistent;
  final DateTime limit;
  int step;

  BigInt? clientRandom;
  BigInt? serverRandom;
  BigInt? preMasterSecret;
  EncryptionKey? sessionEncryptionKey;
  String? randomValue;
}
