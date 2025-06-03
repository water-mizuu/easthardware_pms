import 'package:bloc/bloc.dart';
import 'package:easthardware_pms/domain/repository/user_repository.dart';
import 'package:equatable/equatable.dart';

part 'new_password_form_event.dart';
part 'new_password_form_state.dart';

class NewPasswordFormBloc extends Bloc<NewPasswordFormEvent, NewPasswordFormState> {
  NewPasswordFormBloc({required this.userRepository}) : super(const NewPasswordFormState()) {
    on<NewPasswordChanged>(_onNewPasswordChanged);
    on<ConfirmPasswordChanged>(_onConfirmPasswordChanged);
    on<NewPasswordFormSubmitted>(_onFormSubmitted);
  }

  final UserRepository userRepository;
  String? _username;

  // Add this method to set the username
  void setUsername(String username) {
    _username = username;
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
    // Add validation for username
    if (_username == null || _username!.isEmpty) {
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

    print('Submitting new password for $_username: ${state.newPassword}');

    try {
      // Fix: use _username instead of username
      await userRepository.updatePassword(_username!, state.newPassword);

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
