part of 'authentication_bloc.dart';

enum AuthenticationStatus { unknown, loading, success, failure }

enum FormElement { username, password, passwordVerification, securityQuestion, securityAnswer }

class ErrorMessage {
  const ErrorMessage({required this.message, required this.target});

  final String message;
  final FormElement target;
}

class AuthenticationState {
  AuthenticationState({
    this.status = AuthenticationStatus.unknown,
    this.user,
    this.loginAttempts = 0,
    this.errors = const [],
  });

  final AuthenticationStatus status;
  final User? user;
  final int loginAttempts;
  final List<ErrorMessage> errors;

  AuthenticationState Function({
    AuthenticationStatus status,
    User? user,
    int loginAttempts,
    List<ErrorMessage> errors,
  }) get copyWith {
    return ({
      Object? status = undefined,
      Object? user = undefined,
      Object? loginAttempts = undefined,
      Object? errors = undefined,
    }) {
      return AuthenticationState(
        status: status.or(this.status),
        user: user.or(this.user),
        loginAttempts: loginAttempts.or(this.loginAttempts),
        errors: errors.or(this.errors),
      );
    };
  }
}
