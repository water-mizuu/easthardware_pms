part of 'expense_breakdown_cubit.dart';

class ExpenseBreakdownState {
  const ExpenseBreakdownState({
    required this.choice,
  });

  factory ExpenseBreakdownState.initial() =>
      const ExpenseBreakdownState(choice: ExpenseBreakdownChoice.thisMonth);
  final ExpenseBreakdownChoice choice;

  ExpenseBreakdownState copyWith({
    ExpenseBreakdownChoice? choice,
  }) {
    return ExpenseBreakdownState(
      choice: choice ?? this.choice,
    );
  }
}
