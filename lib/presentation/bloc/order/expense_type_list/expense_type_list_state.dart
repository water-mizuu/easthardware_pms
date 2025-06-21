part of 'expense_type_list_bloc.dart';

class ExpenseTypeListState with EquatableMixin {
  const ExpenseTypeListState({
    this.expenseTypes = const [],
    this.status = DataStatus.initial,
  });

  final List<ExpenseType> expenseTypes;
  final DataStatus status;

  ExpenseTypeListState Function({
    List<ExpenseType>? expenseTypes,
    DataStatus? status,
  }) get copyWith {
    return ({
      Object? expenseTypes = undefined,
      Object? status = undefined,
    }) {
      return ExpenseTypeListState(
        expenseTypes: expenseTypes.or(this.expenseTypes),
        status: status.or(this.status),
      );
    };
  }

  @override
  List<Object?> get props => [expenseTypes, status];
}
