part of 'login_form_bloc.dart';

class LoginFormState with EquatableMixin {
  const LoginFormState({
    this.username = '',
    this.password = '',
    this.errors = const {},
    this.status = FormStatus.initial,
  });
  final String username;
  final String password;
  final ErrorMessages errors;
  final FormStatus status;

  LoginFormState Function({
    String username,
    String password,
    ErrorMessages errors,
    FormStatus status,
  }) get copyWith {
    return ({
      Object? username = undefined,
      Object? password = undefined,
      Object? errors = undefined,
      Object? status = undefined,
    }) {
      return LoginFormState(
        username: username.or(this.username),
        password: password.or(this.password),
        errors: errors.or(this.errors),
        status: status.or(this.status),
      );
    };
  }

  @override
  List<Object?> get props => [username, password, errors, status];

  String? get usernameError => errors[FormElement.username];
  String? get passwordError => errors[FormElement.password];
}
