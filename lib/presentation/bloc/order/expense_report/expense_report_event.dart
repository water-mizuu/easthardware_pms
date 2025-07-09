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

class ExpenseReportSetRowLimitEvent extends ExpenseReportEvent {
  const ExpenseReportSetRowLimitEvent(this.rowLimit);

  final int? rowLimit;

  @override
  List<Object?> get props => [rowLimit];
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

class ExpenseReportSetSearchQueryEvent extends ExpenseReportEvent {
  const ExpenseReportSetSearchQueryEvent(this.searchQuery);

  final String searchQuery;

  @override
  List<Object?> get props => [searchQuery];
}

class ExpenseReportSetPaymentStatusFilterEvent extends ExpenseReportEvent {
  const ExpenseReportSetPaymentStatusFilterEvent(this.paymentStatusFilter);

  final ExpensePaymentStatusFilter paymentStatusFilter;

  @override
  List<Object?> get props => [paymentStatusFilter];
}

class ExpenseReportSetExpenseTypeEvent extends ExpenseReportEvent {
  const ExpenseReportSetExpenseTypeEvent(this.expenseType);

  final ExpenseType? expenseType;

  @override
  List<Object?> get props => [expenseType];
}

class ExpenseReportSetPayeeEvent extends ExpenseReportEvent {
  const ExpenseReportSetPayeeEvent(this.payee);

  final String? payee;

  @override
  List<Object?> get props => [payee];
}
