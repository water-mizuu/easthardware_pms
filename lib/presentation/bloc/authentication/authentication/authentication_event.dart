part of 'authentication_bloc.dart';

sealed class AuthenticationEvent {
  const AuthenticationEvent();
}

class AuthenticationLoginEvent implements AuthenticationEvent {
  const AuthenticationLoginEvent({required this.username, required this.password});

  final String username;
  final String password;
}

class AuthenticationLogoutEvent implements AuthenticationEvent {
  const AuthenticationLogoutEvent();
}

class AuthenticationPostLogoutEvent implements AuthenticationEvent {
  const AuthenticationPostLogoutEvent();
}

class AuthenticationResetEvent implements AuthenticationEvent {
  const AuthenticationResetEvent();
}
