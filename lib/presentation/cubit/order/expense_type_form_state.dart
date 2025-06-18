part of 'expense_type_form_cubit.dart';

class ExpenseTypeFormState {
  const ExpenseTypeFormState({
    this.name = '',
    this.status = FormStatus.initial,
    this.errorMessage,
  });

  final String name;
  final FormStatus status;
  final String? errorMessage;

  ExpenseTypeFormState Function({
    String? name,
    FormStatus? status,
    String? errorMessage,
  }) get copyWith {
    return ({
      Object? name = undefined,
      Object? status = undefined,
      Object? errorMessage = undefined,
    }) {
      return ExpenseTypeFormState(
        name: name.or(this.name),
        status: status.or(this.status),
        errorMessage: errorMessage.or(this.errorMessage),
      );
    };
  }
}
