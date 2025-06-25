import 'package:bloc/bloc.dart';
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
    required ResetFormState initialState,
  }) : super(initialState) {
    on<ResetFormUsernameChanged>(_onUsernameChanged);
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
      status: ResetFormStatus.loading,
      questions: const [],
      selectedQuestion: '',
    ));

    if (username.isEmpty) {
      emit(state.copyWith(status: ResetFormStatus.initial));
      return;
    }

    if (username == "admin") {
      emit(state.copyWith(
        status: ResetFormStatus.error,
        errorMessage: 'Admin user cannot reset password',
        questions: const [],
        selectedQuestion: '',
      ));
      return;
    }

    try {
      final user = await userRepository.getUserByUsername(username).then((p) => p!);
      final questions = await securityQuestionRepository.getSecurityQuestionsByUserId(user.id!);
      emit(state.copyWith(
        questions: questions,
        status: ResetFormStatus.loaded,
        errorMessage: '',
      ));
    } catch (e) {
      emit(state.copyWith(
        questions: const [],
        status: ResetFormStatus.error,
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

  void _onAnswerChanged(ResetFormAnswerChanged event, Emitter<ResetFormState> emit) {
    emit(state.copyWith(answer: event.answer));
  }

  Future<void> _onFormSubmitted(ResetFormSubmitted event, Emitter<ResetFormState> emit) async {
    if (!state.isValid) {
      emit(state.copyWith(
        status: ResetFormStatus.error,
        errorMessage: 'Please fill in all fields',
      ));
      return;
    }

    emit(state.copyWith(status: ResetFormStatus.loading));

    try {
      // Find the security question that matches the selected question
      final selectedSecurityQuestion = state.questions //
          .firstWhere((q) => q.question == state.selectedQuestion);

      // Verify the answer (you might want to hash this for security)
      if (selectedSecurityQuestion.answer.toLowerCase().trim() ==
          state.answer.toLowerCase().trim()) {
        emit(state.copyWith(
          status: ResetFormStatus.success,
          errorMessage: '',
        ));
      } else {
        emit(state.copyWith(
          status: ResetFormStatus.error,
          errorMessage: 'Invalid answer',
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        status: ResetFormStatus.error,
        errorMessage: 'Verification failed. Please try again.',
      ));
    }
  }
}
