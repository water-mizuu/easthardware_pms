part of 'login_form_bloc.dart';

class LoginFormState {
  const LoginFormState({
    this.username = '',
    this.password = '',
    this.usernameError,
    this.passwordError,
    this.status = FormStatus.initial,
  });
  final String username;
  final String password;
  final String? usernameError;
  final String? passwordError;
  final FormStatus status;

  LoginFormState Function({
    String username,
    String password,
    String? usernameError,
    String? passwordError,
    FormStatus status,
  }) get copyWith {
    return ({
      Object? username = undefined,
      Object? password = undefined,
      Object? usernameError = undefined,
      Object? passwordError = undefined,
      Object? status = undefined,
    }) {
      return LoginFormState(
        username: username.or(this.username),
        password: password.or(this.password),
        usernameError: usernameError.or(this.usernameError),
        passwordError: passwordError.or(this.passwordError),
        status: status.or(this.status),
      );
    };
  }
}
