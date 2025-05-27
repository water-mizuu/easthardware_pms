part of 'login_form_bloc.dart';

sealed class LoginFormEvent {}

class LoginFormUsernameChanged extends LoginFormEvent {
  LoginFormUsernameChanged(this.username);
  final String username;
}

class LoginFormPasswordChanged extends LoginFormEvent {
  LoginFormPasswordChanged(this.password);
  final String password;
}

class LoginFormButtonPressed extends LoginFormEvent {}

class LoginFormReturned extends LoginFormEvent {}

class LoginFormResetEvent extends LoginFormEvent {}
