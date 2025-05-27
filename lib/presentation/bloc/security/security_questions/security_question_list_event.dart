part of 'security_question_list_bloc.dart';

sealed class SecurityQuestionListEvent extends Equatable {
  const SecurityQuestionListEvent();

  @override
  List<Object> get props => [];
}

class FetchSecurityQuestionsEvent extends SecurityQuestionListEvent {
  const FetchSecurityQuestionsEvent();
}

class FilterSecurityQuestionsEvent extends SecurityQuestionListEvent {
  const FilterSecurityQuestionsEvent(this.userId);
  final int userId;
}

class AddSecurityQuestionEvent extends SecurityQuestionListEvent {
  const AddSecurityQuestionEvent(this.question);
  final SecurityQuestion question;
}

class UpdateSecurityQuestionEvent extends SecurityQuestionListEvent {
  const UpdateSecurityQuestionEvent(this.question);
  final SecurityQuestion question;
}

class DeleteSecurityQuestionEvent extends SecurityQuestionListEvent {
  const DeleteSecurityQuestionEvent(this.question);
  final SecurityQuestion question;
}
