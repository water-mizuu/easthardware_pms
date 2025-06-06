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

  NewPasswordFormState Function({
    String username,
    String newPassword,
    String confirmPassword,
    FormStatus status,
    String errorMessage,
  }) get copyWith {
    return ({
      Object? username = undefined,
      Object? newPassword = undefined,
      Object? confirmPassword = undefined,
      Object? status = undefined,
      Object? errorMessage = undefined,
    }) {
      return NewPasswordFormState(
        username: username.or(this.username),
        newPassword: newPassword.or(this.newPassword),
        confirmPassword: confirmPassword.or(this.confirmPassword),
        status: status.or(this.status),
        errorMessage: errorMessage.or(this.errorMessage),
      );
    };
  }

  bool get isValid =>
      newPassword.isNotEmpty &&
      confirmPassword.isNotEmpty &&
      _isPasswordStrong(newPassword) &&
      newPassword == confirmPassword;

  bool _isPasswordStrong(String password) {
    final passwordRegex = RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[\W_]).{8,}$');
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
