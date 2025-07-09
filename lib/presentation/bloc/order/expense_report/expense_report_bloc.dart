import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:easthardware_pms/domain/models/expense_type.dart';
import 'package:easthardware_pms/domain/models/order.dart';
import 'package:easthardware_pms/presentation/views/reports/expense_report/'
    'expense_query_data.dart';
import 'package:easthardware_pms/utils/undefined.dart';
import 'package:equatable/equatable.dart';
import 'package:fluent_ui/fluent_ui.dart';

part 'expense_report_event.dart';
part 'expense_report_state.dart';

class ExpenseReportBloc extends Bloc<ExpenseReportEvent, ExpenseReportState> {
  ExpenseReportBloc(
    List<Order> allOrders,
    List<ExpenseType> allExpenseTypes,
  ) : super(ExpenseReportState(
          allOrders: allOrders,
          allExpenseTypes: allExpenseTypes,
          queryData: ExpenseQueryData.empty(),
        )) {
    on<ExpenseReportInitializeEvent>(_onInitialize);
    on<ExpenseReportSetGeneratingEvent>(_onSetGenerating);
    on<ExpenseReportSetStartDateEvent>(_onSetStartDate);
    on<ExpenseReportSetEndDateEvent>(_onSetEndDate);
    on<ExpenseReportSetSortByEvent>(_onSetSortBy);
    on<ExpenseReportSetRowLimitEvent>(_onSetRowLimit);
    on<ExpenseReportSetOverlayEvent>(_onSetOverlay);
    on<ExpenseReportRemoveOverlayEvent>(_onRemoveOverlay);
    on<ExpenseReportUpdateOrdersEvent>(_onUpdateOrders);
    on<ExpenseReportUpdateExpenseTypesEvent>(_onUpdateExpenseTypes);
    on<ExpenseReportSetSearchQueryEvent>(_onSetSearchQuery);
    on<ExpenseReportSetPaymentStatusFilterEvent>(_onSetPaymentStatusFilter);
    on<ExpenseReportSetExpenseTypeEvent>(_onSetExpenseType);
    on<ExpenseReportSetPayeeEvent>(_onSetPayee);

    // Initialize the query data
    add(const ExpenseReportInitializeEvent());
  }

  Future<void> _onInitialize(
    ExpenseReportInitializeEvent event,
    Emitter<ExpenseReportState> emit,
  ) async {
    _recalculateExpenseData(emit);
  }

  void _onSetGenerating(ExpenseReportSetGeneratingEvent event, Emitter<ExpenseReportState> emit) {
    emit(state.copyWith(isGenerating: event.isGenerating));
  }

  void _onSetStartDate(ExpenseReportSetStartDateEvent event, Emitter<ExpenseReportState> emit) {
    emit(state.copyWith(
      queryData: state.queryData.copyWith(startDate: event.startDate),
    ));
    _recalculateExpenseData(emit);
  }

  void _onSetEndDate(ExpenseReportSetEndDateEvent event, Emitter<ExpenseReportState> emit) {
    emit(state.copyWith(
      queryData: state.queryData.copyWith(endDate: event.endDate),
    ));
    _recalculateExpenseData(emit);
  }

  void _onSetSortBy(ExpenseReportSetSortByEvent event, Emitter<ExpenseReportState> emit) {
    emit(state.copyWith(
      queryData: state.queryData.copyWith(sortBy: event.sortBy),
    ));
    _recalculateExpenseData(emit);
  }

  FutureOr<void> _onSetRowLimit(
    ExpenseReportSetRowLimitEvent event,
    Emitter<ExpenseReportState> emit,
  ) {
    emit(state.copyWith(queryData: state.queryData.copyWith(rowLimit: event.rowLimit)));
    _recalculateExpenseData(emit);
  }

  void _onSetSearchQuery(
    ExpenseReportSetSearchQueryEvent event,
    Emitter<ExpenseReportState> emit,
  ) {
    emit(state.copyWith(
      queryData: state.queryData.copyWith(searchQuery: event.searchQuery),
    ));
    _recalculateExpenseData(emit);
  }

  void _onSetPaymentStatusFilter(
    ExpenseReportSetPaymentStatusFilterEvent event,
    Emitter<ExpenseReportState> emit,
  ) {
    emit(state.copyWith(
      queryData: state.queryData.copyWith(paymentStatusFilter: event.paymentStatusFilter),
    ));
    _recalculateExpenseData(emit);
  }

  void _onSetExpenseType(
    ExpenseReportSetExpenseTypeEvent event,
    Emitter<ExpenseReportState> emit,
  ) {
    emit(state.copyWith(
      queryData: state.queryData.copyWith(selectedExpenseType: event.expenseType),
    ));
    _recalculateExpenseData(emit);
  }

  void _onSetPayee(
    ExpenseReportSetPayeeEvent event,
    Emitter<ExpenseReportState> emit,
  ) {
    emit(state.copyWith(
      queryData: state.queryData.copyWith(selectedPayee: event.payee),
    ));
    _recalculateExpenseData(emit);
  }

  void _onSetOverlay(ExpenseReportSetOverlayEvent event, Emitter<ExpenseReportState> emit) {
    emit(state.copyWith(overlayEntry: event.overlayEntry));
  }

  void _onRemoveOverlay(ExpenseReportRemoveOverlayEvent event, Emitter<ExpenseReportState> emit) {
    final overlay = state.overlayEntry;
    overlay?.remove();
    emit(state.copyWith(overlayEntry: null));
  }

  void _onUpdateOrders(ExpenseReportUpdateOrdersEvent event, Emitter<ExpenseReportState> emit) {
    emit(state.copyWith(allOrders: event.orders));
    _recalculateExpenseData(emit);
  }

  void _onUpdateExpenseTypes(
      ExpenseReportUpdateExpenseTypesEvent event, Emitter<ExpenseReportState> emit) {
    emit(state.copyWith(allExpenseTypes: event.expenseTypes));
    _recalculateExpenseData(emit);
  }

  void _recalculateExpenseData(Emitter<ExpenseReportState> emit) {
    final orders = state.allOrders;
    final expenseTypes = state.allExpenseTypes;

    // Use the call method of queryData to filter and sort the data
    final expenseData = state.queryData.call(orders, expenseTypes);

    // Calculate expense summary by type
    final expenseSummaryMap = <int, ExpenseExtras>{};
    for (final data in expenseData) {
      final id = data.expenseType.id ?? -1;
      final current = expenseSummaryMap[id];
      if (current == null) {
        expenseSummaryMap[id] = ExpenseExtras(
          expenseType: data.expenseType,
          totalAmount: data.amountDue,
          orderCount: 1,
        );
      } else {
        expenseSummaryMap[id] = current.copyWith(
          totalAmount: current.totalAmount + data.amountDue,
          orderCount: current.orderCount + 1,
        );
      }
    }

    final expenseSummary = expenseSummaryMap.values.toList();

    emit(state.copyWith(
      queryData: state.queryData.copyWith(
        expenseData: expenseData,
        expenseSummary: expenseSummary,
      ),
    ));
  }
}
