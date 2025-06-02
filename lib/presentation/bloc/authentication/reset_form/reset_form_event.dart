part of 'reset_form_bloc.dart';

abstract class ResetFormEvent extends Equatable {
  const ResetFormEvent();

  @override
  List<Object> get props => [];
}

class UsernameChanged extends ResetFormEvent {
  const UsernameChanged(this.username);

  final String username;

  @override
  List<Object> get props => [username];
}

class SecurityQuestionSelected extends ResetFormEvent {
  const SecurityQuestionSelected(this.question);

  final String question;

  @override
  List<Object> get props => [question];
}

class AnswerChanged extends ResetFormEvent {
  const AnswerChanged(this.answer);

  final String answer;

  @override
  List<Object> get props => [answer];
}

class FormSubmitted extends ResetFormEvent {
  const FormSubmitted();
}
