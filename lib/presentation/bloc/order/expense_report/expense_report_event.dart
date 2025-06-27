part of 'expense_report_bloc.dart';

abstract class ExpenseReportEvent extends Equatable {
  const ExpenseReportEvent();

  @override
  List<Object?> get props => [];
}

class ExpenseReportInitializeEvent extends ExpenseReportEvent {
  const ExpenseReportInitializeEvent();
}

class ExpenseReportSetGeneratingEvent extends ExpenseReportEvent {
  const ExpenseReportSetGeneratingEvent(this.isGenerating);

  final bool isGenerating;

  @override
  List<Object?> get props => [isGenerating];
}

class ExpenseReportSetStartDateEvent extends ExpenseReportEvent {
  const ExpenseReportSetStartDateEvent(this.startDate);

  final DateTime startDate;

  @override
  List<Object?> get props => [startDate];
}

class ExpenseReportSetEndDateEvent extends ExpenseReportEvent {
  const ExpenseReportSetEndDateEvent(this.endDate);

  final DateTime endDate;

  @override
  List<Object?> get props => [endDate];
}

class ExpenseReportSetSortByEvent extends ExpenseReportEvent {
  const ExpenseReportSetSortByEvent(this.sortBy);

  final ExpenseReportSortBy sortBy;

  @override
  List<Object?> get props => [sortBy];
}

class ExpenseReportSetTakeEvent extends ExpenseReportEvent {
  const ExpenseReportSetTakeEvent(this.take);

  final int? take;

  @override
  List<Object?> get props => [take];
}

class ExpenseReportSetOverlayEvent extends ExpenseReportEvent {
  const ExpenseReportSetOverlayEvent(this.overlayEntry);

  final OverlayEntry? overlayEntry;

  @override
  List<Object?> get props => [overlayEntry];
}

class ExpenseReportRemoveOverlayEvent extends ExpenseReportEvent {
  const ExpenseReportRemoveOverlayEvent();
}

class ExpenseReportUpdateOrdersEvent extends ExpenseReportEvent {
  const ExpenseReportUpdateOrdersEvent(this.orders);

  final List<Order> orders;

  @override
  List<Object?> get props => [orders];
}

class ExpenseReportUpdateExpenseTypesEvent extends ExpenseReportEvent {
  const ExpenseReportUpdateExpenseTypesEvent(this.expenseTypes);

  final List<ExpenseType> expenseTypes;

  @override
  List<Object?> get props => [expenseTypes];
}
