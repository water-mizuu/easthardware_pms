part of 'new_password_form_bloc.dart';

enum FormStatus { initial, loading, loaded, success, error }

class NewPasswordFormState extends Equatable {
  const NewPasswordFormState({
    this.newPassword = '',
    this.confirmPassword = '',
    this.status = FormStatus.initial,
    this.errorMessage = '',
  });

  final String newPassword;
  final String confirmPassword;
  final FormStatus status;
  final String errorMessage;

  NewPasswordFormState copyWith({
    String? newPassword,
    String? confirmPassword,
    FormStatus? status,
    String? errorMessage,
  }) {
    return NewPasswordFormState(
      newPassword: newPassword ?? this.newPassword,
      confirmPassword: confirmPassword ?? this.confirmPassword,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  bool get isValid =>
      newPassword.isNotEmpty &&
      confirmPassword.isNotEmpty &&
      newPassword == confirmPassword;

  @override
  List<Object> get props => [
        newPassword,
        confirmPassword,
        status,
        errorMessage,
      ];
}
