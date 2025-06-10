part of 'login_form_bloc.dart';

sealed class LoginFormEvent {}

class LoginFormUsernameChanged implements LoginFormEvent {
  LoginFormUsernameChanged(this.username);
  final String username;
}

class LoginFormPasswordChanged implements LoginFormEvent {
  LoginFormPasswordChanged(this.password);
  final String password;
}

class LoginFormButtonPressed implements LoginFormEvent {}

class LoginFormReturned implements LoginFormEvent {}

class LoginFormResetEvent implements LoginFormEvent {}

class LoginFormSubmitFailed implements LoginFormEvent {
  const LoginFormSubmitFailed(this.errors);

  final List<ErrorMessage> errors;
}

class LoginFormClearErrors implements LoginFormEvent {
  const LoginFormClearErrors();
}
