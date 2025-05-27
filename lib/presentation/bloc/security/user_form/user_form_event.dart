part of 'user_form_bloc.dart';

sealed class UserFormEvent extends Equatable {
  const UserFormEvent();

  @override
  List<Object> get props => [];
}

class UserIdChangedEvent extends UserFormEvent {
  final int userId;
  const UserIdChangedEvent(this.userId);
}

class FirstNameFieldChangedEvent extends UserFormEvent {
  final String firstName;
  const FirstNameFieldChangedEvent(this.firstName);
}

class LastNameFieldChangedEvent extends UserFormEvent {
  final String lastName;
  const LastNameFieldChangedEvent(this.lastName);
}

class UsernameFieldChangedEvent extends UserFormEvent {
  final String username;
  const UsernameFieldChangedEvent(this.username);
}

class PasswordFieldChangedEvent extends UserFormEvent {
  final String password;
  const PasswordFieldChangedEvent(this.password);
}

class ConfirmPasswordFieldChangedEvent extends UserFormEvent {
  final String confirmPassword;
  const ConfirmPasswordFieldChangedEvent(this.confirmPassword);
}

class AccessLevelFieldChangedEvent extends UserFormEvent {
  final String accessLevel;
  const AccessLevelFieldChangedEvent(this.accessLevel);
}

class QuestionFieldChangedEvent extends UserFormEvent {
  final int index;
  final String question;
  const QuestionFieldChangedEvent(this.question, this.index);
}

class AnswerFieldChangedEvent extends UserFormEvent {
  final int index;
  final String answer;
  const AnswerFieldChangedEvent(this.answer, this.index);
}

class FormButtonPressedEvent extends UserFormEvent {}

class FormSubmittedEvent extends UserFormEvent {}

class FormResetEvent extends UserFormEvent {}
