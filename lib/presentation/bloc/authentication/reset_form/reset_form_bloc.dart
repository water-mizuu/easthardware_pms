import 'package:bloc/bloc.dart';
import 'package:dart_bloc_concurrency/dart_bloc_concurrency.dart';
import 'package:easthardware_pms/domain/models/security_question.dart';
import 'package:easthardware_pms/domain/repository/security_question_repository.dart';
import 'package:easthardware_pms/domain/repository/user_repository.dart';
import 'package:easthardware_pms/utils/undefined.dart';
import 'package:equatable/equatable.dart';

part 'reset_form_event.dart';
part 'reset_form_state.dart';

class ResetFormBloc extends Bloc<ResetFormEvent, ResetFormState> {
  ResetFormBloc({
    required this.userRepository,
    required this.securityQuestionRepository,
  }) : super(const ResetFormState()) {
    on<ResetFormUsernameChanged>(_onUsernameChanged,
        transformer: debounce(const Duration(seconds: 1)));
    on<ResetFormSecurityQuestionSelected>(_onSecurityQuestionSelected);
    on<ResetFormAnswerChanged>(_onAnswerChanged);
    on<ResetFormSubmitted>(_onFormSubmitted);
  }

  final UserRepository userRepository;
  final SecurityQuestionRepository securityQuestionRepository;

  Future<void> _onUsernameChanged(
    ResetFormUsernameChanged event,
    Emitter<ResetFormState> emit,
  ) async {
    final username = event.username.trim();

    emit(state.copyWith(
      username: username,
      status: FormStatus.loading,
      questions: [],
      selectedQuestion: '',
    ));

    if (username.isEmpty) {
      emit(state.copyWith(status: FormStatus.initial));
      return;
    }

    if (username == "admin") {
      emit(state.copyWith(
        status: FormStatus.error,
        errorMessage: 'Admin user cannot reset password',
        questions: [],
        selectedQuestion: '',
      ));
      return;
    }

    try {
      final user = await userRepository.getUserByUsername(username);
      if (user == null) {
        emit(state.copyWith(
          status: FormStatus.error,
          errorMessage: 'User not found',
          questions: [],
          selectedQuestion: '',
        ));
        return;
      }

      final questions = await securityQuestionRepository
          .getSecurityQuestionsByUserId(user.id!);
      emit(state.copyWith(
        questions: questions,
        status: FormStatus.loaded,
        errorMessage: '',
      ));
      //
    } catch (e) {
      emit(state.copyWith(
        questions: [],
        status: FormStatus.error,
        errorMessage: 'Failed to load security questions',
      ));
    }
  }

  void _onSecurityQuestionSelected(
    ResetFormSecurityQuestionSelected event,
    Emitter<ResetFormState> emit,
  ) {
    emit(state.copyWith(selectedQuestion: event.question));
  }

  void _onAnswerChanged(
      ResetFormAnswerChanged event, Emitter<ResetFormState> emit) {
    emit(state.copyWith(answer: event.answer));
  }

  Future<void> _onFormSubmitted(
      ResetFormSubmitted event, Emitter<ResetFormState> emit) async {
    if (!state.isValid) {
      emit(state.copyWith(
        status: FormStatus.error,
        errorMessage: 'Please fill in all fields',
      ));
      return;
    }

    emit(state.copyWith(status: FormStatus.loading));

    try {
      // Find the security question that matches the selected question
      final selectedSecurityQuestion = state.questions.firstWhere(
        (q) => q.question == state.selectedQuestion,
      );

      // Verify the answer (you might want to hash this for security)
      if (selectedSecurityQuestion.answer.toLowerCase().trim() ==
          state.answer.toLowerCase().trim()) {
        emit(state.copyWith(
          status: FormStatus.success,
          errorMessage: '',
        ));
      } else {
        emit(state.copyWith(
          status: FormStatus.error,
          errorMessage: 'Incorrect answer to security question',
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        status: FormStatus.error,
        errorMessage: 'Verification failed. Please try again.',
      ));
    }
  }
}
