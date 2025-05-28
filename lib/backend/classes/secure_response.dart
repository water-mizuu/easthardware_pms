import 'package:easthardware_pms/domain/services/cryptography_service.dart';
import 'package:shelf/shelf.dart';

/// A wrapper around the Shelf Response class that uses an encrypted body.
///   It automatically encrypts the body using a symmetric encryption key
///   provided during the response creation.
class SecureResponse extends Response {
  SecureResponse.ok(
    String body,
    BigInt encryptionKey, {
    super.context,
    super.encoding,
    super.headers,
  }) : super.ok(_encryptSymmetric(body, encryptionKey));

  SecureResponse.badRequest({
    String? body,
    BigInt? encryptionKey,
    super.context,
    super.encoding,
    super.headers,
  })  : assert((body == null) == (encryptionKey == null)),
        super.badRequest(
          body:
              body != null && encryptionKey != null ? _encryptSymmetric(body, encryptionKey) : null,
        );

  SecureResponse.unauthorized(
    String body,
    BigInt encryptionKey, {
    super.context,
    super.encoding,
    super.headers,
  }) : super.unauthorized(_encryptSymmetric(body, encryptionKey));

  SecureResponse.forbidden(
    String body,
    BigInt encryptionKey, {
    super.context,
    super.encoding,
    super.headers,
  }) : super.forbidden(_encryptSymmetric(body, encryptionKey));

  SecureResponse.notFound(
    String body,
    BigInt encryptionKey, {
    super.context,
    super.encoding,
    super.headers,
  }) : super.notFound(_encryptSymmetric(body, encryptionKey));
}

String _encryptSymmetric(String value, BigInt key) {
  return CryptographyService.encryptSymmetric(value, key);
}
