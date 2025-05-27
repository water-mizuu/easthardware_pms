class AuthenticationException implements Exception {

  AuthenticationException(this.message);
  final String message;

  @override
  String toString() => 'AuthenticationException: $message';
}

class DatabaseException implements Exception {

  DatabaseException(this.message);
  final String message;

  @override
  String toString() => 'DatabaseException: $message';
}

class NetworkException implements Exception {

  NetworkException(this.message);
  final String message;

  @override
  String toString() => 'NetworkException: $message';
}

class ValidationException implements Exception {

  ValidationException(this.message);
  final String message;

  @override
  String toString() => 'ValidationException: $message';
}

class ArgumentException implements Exception {

  ArgumentException(this.message);
  final String message;

  @override
  String toString() => 'ArgumentException: $message';
}
