part of 'expense_type_display_cubit.dart';

class ExpenseTypeDisplayState extends Equatable {
  const ExpenseTypeDisplayState({
    this.allExpenseTypes,
    this.filteredExpenseTypes,
    this.sortBy = ExpenseTypeDisplaySortBy.idAscending,
    this.sortAscending = true,
  });
  final List<DisplayExpenseType>? allExpenseTypes;
  final List<DisplayExpenseType>? filteredExpenseTypes;
  final ExpenseTypeDisplaySortBy sortBy;
  final bool sortAscending;

  ExpenseTypeDisplayState copyWith({
    List<DisplayExpenseType>? allExpenseTypes,
    List<DisplayExpenseType>? filteredExpenseTypes,
    ExpenseTypeDisplaySortBy? sortBy,
    bool? sortAscending,
  }) {
    return ExpenseTypeDisplayState(
      allExpenseTypes: allExpenseTypes ?? this.allExpenseTypes,
      filteredExpenseTypes: filteredExpenseTypes ?? this.filteredExpenseTypes,
      sortBy: sortBy ?? this.sortBy,
      sortAscending: sortAscending ?? this.sortAscending,
    );
  }

  @override
  List<Object?> get props => [
        allExpenseTypes,
        filteredExpenseTypes,
        sortBy,
        sortAscending,
      ];
}
