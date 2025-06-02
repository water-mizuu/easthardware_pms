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

  ResetFormState copyWith({
    String? username,
    String? selectedQuestion,
    String? answer,
    List<SecurityQuestion>? questions,
    FormStatus? status,
    String? errorMessage,
  }) {
    return ResetFormState(
      username: username ?? this.username,
      selectedQuestion: selectedQuestion ?? this.selectedQuestion,
      answer: answer ?? this.answer,
      questions: questions ?? this.questions,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  bool get isValid =>
      username.isNotEmpty && selectedQuestion.isNotEmpty && answer.isNotEmpty;

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
