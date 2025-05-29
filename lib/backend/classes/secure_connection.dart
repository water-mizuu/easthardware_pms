import 'package:easthardware_pms/backend/extension_types/secure_keys.dart';

/// These are individual encryption tokens. Once a user has been authenticated,
///   the secure connection is established for end to end encryption.
///
/// If the once the connection is said to be persistent, it will not be
///   invalidated until the server clears it on sweep, or the connection is closed.
class SecureConnection {
  SecureConnection({
    required this.secureKey,
    required this.encryptionKey,
    required this.isPersistent,
  });

  final int secureKey;
  final EncryptionKey encryptionKey;
  final bool isPersistent;
}
