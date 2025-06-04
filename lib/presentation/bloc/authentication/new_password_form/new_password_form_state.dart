part of 'new_password_form_bloc.dart';

enum FormStatus { initial, loading, loaded, success, error }

class NewPasswordFormState extends Equatable {
  const NewPasswordFormState({
    this.username = '',
    this.newPassword = '',
    this.confirmPassword = '',
    this.status = FormStatus.initial,
    this.errorMessage = '',
  });

  final String username;
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
      _isPasswordStrong(newPassword) &&
      newPassword == confirmPassword;

  bool _isPasswordStrong(String password) {
    final passwordRegex =
        RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[\W_]).{8,}$');
    return passwordRegex.hasMatch(password);
  }

  @override
  List<Object> get props => [
        newPassword,
        confirmPassword,
        status,
        errorMessage,
      ];
}
