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
  final int userId;
  const FilterSecurityQuestionsEvent(this.userId);
}

class AddSecurityQuestionEvent extends SecurityQuestionListEvent {
  final SecurityQuestion question;
  const AddSecurityQuestionEvent(this.question);
}

class UpdateSecurityQuestionEvent extends SecurityQuestionListEvent {
  final SecurityQuestion question;
  const UpdateSecurityQuestionEvent(this.question);
}

class DeleteSecurityQuestionEvent extends SecurityQuestionListEvent {
  final SecurityQuestion question;
  const DeleteSecurityQuestionEvent(this.question);
}
