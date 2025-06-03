part of 'reset_form_bloc.dart';

abstract class ResetFormEvent extends Equatable {
  const ResetFormEvent();

  @override
  List<Object> get props => [];
}

class ResetFormUsernameChanged extends ResetFormEvent {
  const ResetFormUsernameChanged(this.username);

  final String username;

  @override
  List<Object> get props => [username];
}

class ResetFormSecurityQuestionSelected extends ResetFormEvent {
  const ResetFormSecurityQuestionSelected(this.question);

  final String question;

  @override
  List<Object> get props => [question];
}

class ResetFormAnswerChanged extends ResetFormEvent {
  const ResetFormAnswerChanged(this.answer);

  final String answer;

  @override
  List<Object> get props => [answer];
}

class ResetFormSubmitted extends ResetFormEvent {
  const ResetFormSubmitted();
}
