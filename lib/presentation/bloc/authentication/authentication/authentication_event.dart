part of 'authentication_bloc.dart';

sealed class AuthenticationEvent implements Equatable {
  const AuthenticationEvent();

  @override
  List<Object> get props => [];
}

class AuthenticationLoginEvent with EquatableMixin implements AuthenticationEvent {
  const AuthenticationLoginEvent({required this.username, required this.password});

  final String username;
  final String password;

  @override
  List<Object> get props => [username, password];
}

class AuthenticationLogoutEvent with EquatableMixin implements AuthenticationEvent {
  const AuthenticationLogoutEvent();

  @override
  List<Object> get props => [];
}

class AuthenticationPostLogoutEvent with EquatableMixin implements AuthenticationEvent {
  const AuthenticationPostLogoutEvent();

  @override
  List<Object> get props => [];
}
