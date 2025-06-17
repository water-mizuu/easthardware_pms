part of 'expense_type_list_bloc.dart';

sealed class ExpenseTypeListEvent extends Equatable {
  const ExpenseTypeListEvent();

  @override
  List<Object> get props => [];
}

class FetchAllExpenseTypesEvent extends ExpenseTypeListEvent {
  const FetchAllExpenseTypesEvent();

  @override
  List<Object> get props => [];
}

class AddExpenseTypeEvent extends ExpenseTypeListEvent {
  const AddExpenseTypeEvent(this.expenseType);

  final ExpenseType expenseType;

  @override
  List<Object> get props => [expenseType];
}

class UpdateExpenseTypeEvent extends ExpenseTypeListEvent {
  const UpdateExpenseTypeEvent(this.expenseType);

  final ExpenseType expenseType;

  @override
  List<Object> get props => [expenseType];
}
