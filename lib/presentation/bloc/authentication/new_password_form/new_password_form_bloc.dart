import 'package:bloc/bloc.dart';
import 'package:easthardware_pms/domain/repository/user_repository.dart';
import 'package:equatable/equatable.dart';

part 'new_password_form_event.dart';
part 'new_password_form_state.dart';

class NewPasswordFormBloc
    extends Bloc<NewPasswordFormEvent, NewPasswordFormState> {
  NewPasswordFormBloc({required this.userRepository})
      : super(const NewPasswordFormState()) {
    on<NewPasswordFormUsernameChanged>(_onUsernameChanged);
    on<NewPasswordChanged>(_onNewPasswordChanged);
    on<ConfirmPasswordChanged>(_onConfirmPasswordChanged);
    on<NewPasswordFormSubmitted>(_onFormSubmitted);
  }

  final UserRepository userRepository;
  String? username;

  void _onUsernameChanged(
    NewPasswordFormUsernameChanged event,
    Emitter<NewPasswordFormState> emit,
  ) {
    username = event.username;
  }

  void _onNewPasswordChanged(
    NewPasswordChanged event,
    Emitter<NewPasswordFormState> emit,
  ) {
    emit(state.copyWith(newPassword: event.password));
  }

  void _onConfirmPasswordChanged(
    ConfirmPasswordChanged event,
    Emitter<NewPasswordFormState> emit,
  ) {
    emit(state.copyWith(confirmPassword: event.password));
  }

  Future<void> _onFormSubmitted(
    NewPasswordFormSubmitted event,
    Emitter<NewPasswordFormState> emit,
  ) async {
    print("Current State Username ${username}");
    if (username == null || username!.isEmpty) {
      emit(state.copyWith(
        status: FormStatus.error,
        errorMessage: 'User session expired. Please start over.',
      ));
      return;
    }

    if (!state.isValid) {
      emit(state.copyWith(
        status: FormStatus.error,
        errorMessage: 'Passwords must match and not be empty.',
      ));
      return;
    }

    emit(state.copyWith(status: FormStatus.loading));

    print('Submitting new password for $username: ${state.newPassword}');

    try {
      await userRepository.updatePassword(username!, state.newPassword);

      emit(state.copyWith(status: FormStatus.success, errorMessage: ''));
    } catch (_) {
      print('Error updating password: rawr');
      emit(state.copyWith(
        status: FormStatus.error,
        errorMessage: 'Failed to update password. Try again.',
      ));
    }
  }
}
