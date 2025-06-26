import 'package:bloc/bloc.dart';
import 'package:easthardware_pms/presentation/cubit/order/expense_type_display/display_expense_type.dart';
import 'package:easthardware_pms/presentation/cubit/order/expense_type_display/expense_type_display_enum.dart';
import 'package:equatable/equatable.dart';

part 'expense_type_display_state.dart';

class ExpenseTypeDisplayCubit extends Cubit<ExpenseTypeDisplayState> {
  ExpenseTypeDisplayCubit() : super(const ExpenseTypeDisplayState());

  void updateExpenseTypes(List<DisplayExpenseType> expenseTypes) {
    emit(state.copyWith(
      allExpenseTypes: expenseTypes,
      filteredExpenseTypes: expenseTypes,
    ));
  }

  void updateSearch(String query) {
    if (query.isEmpty) {
      emit(state.copyWith(filteredExpenseTypes: state.allExpenseTypes));
      return;
    }

    final filtered = state.allExpenseTypes
        ?.where((item) => item.expenseType.name.toLowerCase().contains(query.toLowerCase()))
        .toList();

    emit(state.copyWith(filteredExpenseTypes: filtered));
  }

  void updateSort(ExpenseTypeDisplaySortBy sortBy) {
    final currentSortBy = state.sortBy;
    final items = [...?state.filteredExpenseTypes ?? state.allExpenseTypes];

    // Toggle sort direction if the same column is clicked again
    if (sortBy == currentSortBy) {
      switch (sortBy) {
        case ExpenseTypeDisplaySortBy.idAscending:
          return _sortById(items, true);
        case ExpenseTypeDisplaySortBy.idDescending:
          return _sortById(items, false);
        case ExpenseTypeDisplaySortBy.nameAscending:
          return _sortByName(items, false);
        case ExpenseTypeDisplaySortBy.nameDescending:
          return _sortByName(items, true);
        case ExpenseTypeDisplaySortBy.ordersAscending:
          return _sortByOrderCount(items, false);
        case ExpenseTypeDisplaySortBy.ordersDescending:
          return _sortByOrderCount(items, true);
      }
    } else {
      // First time sorting this column
      switch (sortBy) {
        case ExpenseTypeDisplaySortBy.idAscending:
          return _sortById(items, true);
        case ExpenseTypeDisplaySortBy.idDescending:
          return _sortById(items, false);
        case ExpenseTypeDisplaySortBy.nameAscending:
          return _sortByName(items, true);
        case ExpenseTypeDisplaySortBy.nameDescending:
          return _sortByName(items, false);
        case ExpenseTypeDisplaySortBy.ordersAscending:
          return _sortByOrderCount(items, true);
        case ExpenseTypeDisplaySortBy.ordersDescending:
          return _sortByOrderCount(items, false);
      }
    }
  }

  void _sortById(List<DisplayExpenseType> items, bool ascending) {
    items.sort((a, b) => ascending
        ? (a.expenseType.id ?? 0).compareTo(b.expenseType.id ?? 0)
        : (b.expenseType.id ?? 0).compareTo(a.expenseType.id ?? 0));

    emit(
      state.copyWith(
        filteredExpenseTypes: items,
        sortBy: ascending
            ? ExpenseTypeDisplaySortBy.idAscending
            : ExpenseTypeDisplaySortBy.idDescending,
        sortAscending: ascending,
      ),
    );
  }

  void _sortByName(List<DisplayExpenseType> items, bool ascending) {
    items.sort((a, b) => ascending
        ? a.expenseType.name.compareTo(b.expenseType.name)
        : b.expenseType.name.compareTo(a.expenseType.name));

    emit(
      state.copyWith(
        filteredExpenseTypes: items,
        sortBy: ascending
            ? ExpenseTypeDisplaySortBy.nameAscending
            : ExpenseTypeDisplaySortBy.nameDescending,
        sortAscending: ascending,
      ),
    );
  }

  void _sortByOrderCount(List<DisplayExpenseType> items, bool ascending) {
    items.sort((a, b) =>
        ascending ? a.orderCount.compareTo(b.orderCount) : b.orderCount.compareTo(a.orderCount));

    emit(
      state.copyWith(
        filteredExpenseTypes: items,
        sortBy: ascending
            ? ExpenseTypeDisplaySortBy.ordersAscending
            : ExpenseTypeDisplaySortBy.ordersDescending,
        sortAscending: ascending,
      ),
    );
  }
}
