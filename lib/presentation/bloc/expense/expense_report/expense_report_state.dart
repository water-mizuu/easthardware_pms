part of 'expense_report_bloc.dart';

class ExpenseReportState extends Equatable {
  const ExpenseReportState({
    required this.allOrders,
    required this.allExpenseTypes,
    required this.queryData,
    this.isGenerating = false,
    this.overlayEntry,
  });

  final List<Order> allOrders;
  final List<ExpenseType> allExpenseTypes;
  final ExpenseQueryData queryData;
  final bool isGenerating;
  final OverlayEntry? overlayEntry;

  ExpenseReportState Function({
    List<Order> allOrders,
    List<ExpenseType> allExpenseTypes,
    ExpenseQueryData queryData,
    bool isGenerating,
    OverlayEntry? overlayEntry,
  }) get copyWith {
    return ({
      Object? allOrders = undefined,
      Object? allExpenseTypes = undefined,
      Object? queryData = undefined,
      Object? isGenerating = undefined,
      Object? overlayEntry = undefined,
    }) {
      return ExpenseReportState(
        allOrders: allOrders.or(this.allOrders),
        allExpenseTypes: allExpenseTypes.or(this.allExpenseTypes),
        queryData: queryData.or(this.queryData),
        isGenerating: isGenerating.or(this.isGenerating),
        overlayEntry: overlayEntry.or(this.overlayEntry),
      );
    };
  }

  @override
  List<Object?> get props => [allOrders, allExpenseTypes, queryData, isGenerating];
}
