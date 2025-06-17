part of 'expense_type_list_bloc.dart';

class ExpenseTypeListState {
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
      Object? expenseTypes = const [],
      Object? status = DataStatus.initial,
    }) {
      return ExpenseTypeListState(
        expenseTypes:
            expenseTypes == const [] ? this.expenseTypes : expenseTypes as List<ExpenseType>,
        status: status == DataStatus.initial ? this.status : status as DataStatus,
      );
    };
  }
}
