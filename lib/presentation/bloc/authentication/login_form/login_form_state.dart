part of 'login_form_bloc.dart';

class LoginFormState with EquatableMixin {
  const LoginFormState({
    this.username = '',
    this.password = '',
    this.formErrors = const {},
    this.errorMessage,
    this.status = FormStatus.initial,
  });
  final String username;
  final String password;
  final ErrorMessages formErrors;
  final String? errorMessage;
  final FormStatus status;

  LoginFormState Function({
    String username,
    String password,
    ErrorMessages formErrors,
    String? errorMessage,
    FormStatus status,
  }) get copyWith {
    return ({
      Object? username = undefined,
      Object? password = undefined,
      Object? formErrors = undefined,
      Object? errorMessage = undefined,
      Object? status = undefined,
    }) {
      return LoginFormState(
        username: username.or(this.username),
        password: password.or(this.password),
        formErrors: formErrors.or(this.formErrors),
        errorMessage: errorMessage.or(this.errorMessage),
        status: status.or(this.status),
      );
    };
  }

  @override
  List<Object?> get props => [username, password, formErrors, errorMessage, status];

  String? get usernameError => formErrors[FormElement.username];
  String? get passwordError => formErrors[FormElement.password];
}
