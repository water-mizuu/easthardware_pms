part of 'security_question_list_bloc.dart';

class SecurityQuestionListState extends Equatable {
  const SecurityQuestionListState({
    this.securityQuestions = const [],
    this.filteredQuestions = const [],
    this.status = DataStatus.initial,
  });

  final List<SecurityQuestion> securityQuestions;
  final List<SecurityQuestion> filteredQuestions;
  final DataStatus status;

  SecurityQuestionListState Function({
    List<SecurityQuestion> securityQuestions,
    List<SecurityQuestion> filteredQuestions,
    DataStatus status,
  }) get copyWith {
    return ({
      Object? securityQuestions = undefined,
      Object? filteredQuestions = undefined,
      Object? status = undefined,
    }) {
      return SecurityQuestionListState(
        securityQuestions: securityQuestions.or(this.securityQuestions),
        filteredQuestions: filteredQuestions.or(this.filteredQuestions),
        status: status.or(this.status),
      );
    };
  }

  @override
  List<Object> get props => [securityQuestions, filteredQuestions, status];
}
