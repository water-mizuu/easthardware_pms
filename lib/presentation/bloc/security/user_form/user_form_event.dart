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

class OldPasswordFieldChangedEvent extends UserFormEvent {
  const OldPasswordFieldChangedEvent(this.oldPassword);
  final String oldPassword;
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

class UIDChangedEvent extends UserFormEvent {
  const UIDChangedEvent(this.uid);
  final String uid;
}

class FormButtonPressedEvent extends UserFormEvent {}

class FormResetEvent extends UserFormEvent {}

class UpdateUserRequestEvent extends UserFormEvent {}

class LoadSaltAndHashEvent extends UserFormEvent {
  const LoadSaltAndHashEvent({required this.salt, required this.passwordHash});
  final Uint8List salt;
  final Uint8List passwordHash;

  @override
  List<Object> get props => [salt, passwordHash];
}

class SecurityQuestionsUpdatedEvent extends UserFormEvent {
  const SecurityQuestionsUpdatedEvent(this.questions);
  final List<FormQuestion> questions;

  @override
  List<Object> get props => [questions];
}
