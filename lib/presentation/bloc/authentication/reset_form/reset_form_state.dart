part of 'reset_form_bloc.dart';

enum FormStatus { initial, loading, loaded, success, error }

class ResetFormState extends Equatable {
  const ResetFormState({
    this.username = '',
    this.selectedQuestion = '',
    this.answer = '',
    this.questions = const [],
    this.status = FormStatus.initial,
    this.errorMessage = '',
  });

  final String username;
  final String selectedQuestion;
  final String answer;
  final List<SecurityQuestion> questions;
  final FormStatus status;
  final String errorMessage;

  ResetFormState Function({
    String username,
    String selectedQuestion,
    String answer,
    List<SecurityQuestion> questions,
    FormStatus status,
    String errorMessage,
  }) get copyWith {
    return ({
      Object? username = undefined,
      Object? selectedQuestion = undefined,
      Object? answer = undefined,
      Object? questions = undefined,
      Object? status = undefined,
      Object? errorMessage = undefined,
    }) {
      return ResetFormState(
        username: username.or(this.username),
        selectedQuestion: selectedQuestion.or(this.selectedQuestion),
        answer: answer.or(this.answer),
        questions: questions.or(this.questions),
        status: status.or(this.status),
        errorMessage: errorMessage.or(this.errorMessage),
      );
    };
  }

  bool get isValid => username.isNotEmpty && selectedQuestion.isNotEmpty && answer.isNotEmpty;

  @override
  List<Object> get props => [
        username,
        selectedQuestion,
        answer,
        questions,
        status,
        errorMessage,
      ];
}
