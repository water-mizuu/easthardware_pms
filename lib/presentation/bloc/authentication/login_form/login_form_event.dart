part of 'login_form_bloc.dart';

sealed class LoginFormEvent {}

class LoginFormUsernameChanged extends LoginFormEvent {
  final String username;
  LoginFormUsernameChanged(this.username);
}

class LoginFormPasswordChanged extends LoginFormEvent {
  final String password;
  LoginFormPasswordChanged(this.password);
}

class LoginFormButtonPressed extends LoginFormEvent {}

class LoginFormReturned extends LoginFormEvent {}

class LoginFormResetEvent extends LoginFormEvent {}
