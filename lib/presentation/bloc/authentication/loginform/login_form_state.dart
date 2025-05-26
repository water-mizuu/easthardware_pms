part of 'login_form_bloc.dart';

class LoginFormState {
  final String username;
  final String password;
  final FormStatus status;

  const LoginFormState({
    this.username = '',
    this.password = '',
    this.status = FormStatus.initial,
  });

  LoginFormState Function({
    String username,
    String password,
    FormStatus status,
  }) get copyWith {
    return ({
      Object? username = undefined,
      Object? password = undefined,
      Object? status = undefined,
    }) {
      return LoginFormState(
        username: username.or(this.username),
        password: password.or(this.password),
        status: status.or(this.status),
      );
    };
  }
}
