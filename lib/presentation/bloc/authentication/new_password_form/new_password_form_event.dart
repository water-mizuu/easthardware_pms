part of 'new_password_form_bloc.dart';

abstract class NewPasswordFormEvent extends Equatable {
  const NewPasswordFormEvent();

  @override
  List<Object> get props => [];
}

class NewPasswordChanged extends NewPasswordFormEvent {
  const NewPasswordChanged(this.password);
  final String password;

  @override
  List<Object> get props => [password];
}

class ConfirmPasswordChanged extends NewPasswordFormEvent {
  const ConfirmPasswordChanged(this.password);
  final String password;

  @override
  List<Object> get props => [password];
}

class NewPasswordFormSubmitted extends NewPasswordFormEvent {
  const NewPasswordFormSubmitted();
}

class NewPasswordFormReset extends NewPasswordFormEvent {
  const NewPasswordFormReset(this.username);
  final String username;
}
