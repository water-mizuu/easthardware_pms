part of 'authentication_bloc.dart';

typedef ErrorMessages = Map<FormElement, String>;

enum AuthenticationStatus { unknown, loggingIn, loggingOut, success, failure }

enum FormElement {
  username,
  password,
  passwordVerification,
  securityQuestion,
  securityAnswer,
}

// class ErrorMessage {
//   const ErrorMessage({required this.message, required this.target});

//   final String message;
//   final FormElement target;
// }

class AuthenticationState with EquatableMixin {
  const AuthenticationState({
    this.status = AuthenticationStatus.unknown,
    this.user,
    this.loginAttempts = 0,
    this.lastUsername,
    this.formErrors = const {},
    this.previousUser,
    this.repository,
    this.updateFuture,
    this.errorMessage,
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
  final ErrorMessages formErrors;

  final String? errorMessage;

  final AuthenticationRepository? repository;
  final Future<void>? updateFuture;

  AuthenticationState Function({
    AuthenticationStatus status,
    User? user,
    int loginAttempts,
    String? lastUsername,
    ErrorMessages errors,
    User? previousUser,
    AuthenticationRepository? repository,
    Future<void>? updateFuture,
    String? errorMessage,
  }) get copyWith {
    return ({
      Object? status = undefined,
      Object? user = undefined,
      Object? loginAttempts = undefined,
      Object? lastUsername = undefined,
      Object? errors = undefined,
      Object? previousUser = undefined,
      Object? repository = undefined,
      Object? updateFuture = undefined,
      Object? errorMessage = undefined,
    }) {
      return AuthenticationState(
        status: status.or(this.status),
        user: user.or(this.user),
        loginAttempts: loginAttempts.or(this.loginAttempts),
        lastUsername: lastUsername.or(this.lastUsername),
        formErrors: errors.or(formErrors),
        previousUser: previousUser.or(this.previousUser),
        repository: repository.or(this.repository),
        // ignore: discarded_futures
        updateFuture: updateFuture.or(this.updateFuture),
        errorMessage: errorMessage.or(this.errorMessage),
      );
    };
  }

  @override
  List<Object?> get props => [status, user, loginAttempts, lastUsername, formErrors, errorMessage];
}
