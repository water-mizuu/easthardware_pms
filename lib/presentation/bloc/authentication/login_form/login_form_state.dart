part of 'login_form_bloc.dart';

class LoginFormState {

  const LoginFormState({
    this.username = '',
    this.password = '',
    this.status = FormStatus.initial,
  });
  final String username;
  final String password;
  final FormStatus status;

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
