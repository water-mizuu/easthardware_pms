part of 'user_form_bloc.dart';

sealed class UserFormEvent extends Equatable {
  const UserFormEvent();

  @override
  List<Object> get props => [];
}

class UserIdChangedEvent extends UserFormEvent {
  const UserIdChangedEvent(this.userId);
  final int userId;
}

class FirstNameFieldChangedEvent extends UserFormEvent {
  const FirstNameFieldChangedEvent(this.firstName);
  final String firstName;
}

class LastNameFieldChangedEvent extends UserFormEvent {
  const LastNameFieldChangedEvent(this.lastName);
  final String lastName;
}

class UsernameFieldChangedEvent extends UserFormEvent {
  const UsernameFieldChangedEvent(this.username);
  final String username;
}

class PasswordFieldChangedEvent extends UserFormEvent {
  const PasswordFieldChangedEvent(this.password);
  final String password;
}

class ConfirmPasswordFieldChangedEvent extends UserFormEvent {
  const ConfirmPasswordFieldChangedEvent(this.confirmPassword);
  final String confirmPassword;
}

class AccessLevelFieldChangedEvent extends UserFormEvent {
  const AccessLevelFieldChangedEvent(this.accessLevel);
  final String accessLevel;
}

class QuestionFieldChangedEvent extends UserFormEvent {
  const QuestionFieldChangedEvent(this.question, this.index);
  final int index;
  final String question;
}

class AnswerFieldChangedEvent extends UserFormEvent {
  const AnswerFieldChangedEvent(this.answer, this.index);
  final int index;
  final String answer;
}

class FormButtonPressedEvent extends UserFormEvent {}

class FormSubmittedEvent extends UserFormEvent {}

class FormResetEvent extends UserFormEvent {}
