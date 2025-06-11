import 'package:easthardware_pms/presentation/bloc/authentication/'
    'authentication/authentication_bloc.dart';

enum LoginFormExceptionCode {
  userDoesNotExist,
  userAlreadyLoggedIn,
  invalidPassword,
}

class LoginFormException implements Exception {
  const LoginFormException(this.code, this.errors);
  LoginFormException.single(this.code, FormElement target, String message)
      : errors = {target: message};

  final LoginFormExceptionCode code;
  final Map<FormElement, String> errors;
}

class AuthenticationException implements Exception {
  const AuthenticationException(this.message);
  final String message;

  @override
  String toString() => 'AuthenticationException: $message';
}

class DatabaseException implements Exception {
  const DatabaseException(this.message);
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
