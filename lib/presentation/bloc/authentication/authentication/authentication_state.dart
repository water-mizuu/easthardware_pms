part of 'authentication_bloc.dart';

enum AuthenticationStatus { unknown, loggingIn, loggingOut, success, failure }

enum FormElement {
  username,
  password,
  passwordVerification,
  securityQuestion,
  securityAnswer,
}

class ErrorMessage {
  const ErrorMessage({required this.message, required this.target});

  final String message;
  final FormElement target;
}

class AuthenticationState with EquatableMixin {
  AuthenticationState({
    this.status = AuthenticationStatus.unknown,
    this.user,
    this.loginAttempts = 0,
    this.lastUsername,
    this.errors = const [],
    this.previousUser,
  });

  final AuthenticationStatus status;
  final User? user;

  /// This is used to keep track of the user being logged out.
  ///   This is a special attribute that cannot be copied.
  ///   If a subsequent [copyWith] call is made without providing a value for [previousUser],
  ///   it will be assigned 'null'.
  final User? previousUser;

  final int loginAttempts;
  final String? lastUsername;
  final List<ErrorMessage> errors;

  AuthenticationState Function({
    AuthenticationStatus status,
    User? user,
    int loginAttempts,
    String? lastUsername,
    List<ErrorMessage> errors,
    User? previousUser,
  }) get copyWith {
    return ({
      Object? status = undefined,
      Object? user = undefined,
      Object? loginAttempts = undefined,
      Object? lastUsername = undefined,
      Object? errors = undefined,
      Object? previousUser = undefined,
    }) {
      return AuthenticationState(
        status: status.or(this.status),
        user: user.or(this.user),
        loginAttempts: loginAttempts.or(this.loginAttempts),
        lastUsername: lastUsername.or(this.lastUsername),
        errors: errors.or(this.errors),
        previousUser: previousUser is User ? previousUser : null,
      );
    };
  }

  @override
  List<Object?> get props =>
      [status, user, loginAttempts, lastUsername, errors];
}
