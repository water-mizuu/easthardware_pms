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
    on<ExpenseReportSetTakeEvent>(_onSetTake);
    on<ExpenseReportSetOverlayEvent>(_onSetOverlay);
    on<ExpenseReportRemoveOverlayEvent>(_onRemoveOverlay);
    on<ExpenseReportUpdateOrdersEvent>(_onUpdateOrders);
    on<ExpenseReportUpdateExpenseTypesEvent>(_onUpdateExpenseTypes);

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

  FutureOr<void> _onSetTake(ExpenseReportSetTakeEvent event, Emitter<ExpenseReportState> emit) {
    emit(state.copyWith(queryData: state.queryData.copyWith(take: event.take)));
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
    final startDate = state.queryData.startDate;
    final endDate = state.queryData.endDate;
    final sortBy = state.queryData.sortBy;

    // Filter orders by date range
    final filteredOrders = orders.where((order) {
      return order.orderDate.isAfter(startDate) &&
          order.orderDate.isBefore(endDate.add(const Duration(days: 1)));
    }).toList();

    // Map orders to their expense types
    final expenseData = <(Order, ExpenseType)>[];
    for (final order in filteredOrders) {
      final expenseType = expenseTypes.firstWhere(
        (type) => type.id == order.expenseType,
        orElse: () => const ExpenseType(name: 'Unknown'),
      );
      expenseData.add((order, expenseType));
    }

    // Apply sorting
    expenseData.sort(sortBy.compare);

    // Calculate expense summary by type
    final expenseSummaryMap = <int, ExpenseExtras>{};
    for (final (order, expenseType)
        in expenseData.take(state.queryData.take ?? expenseData.length)) {
      final id = expenseType.id ?? -1;
      final current = expenseSummaryMap[id];
      if (current == null) {
        expenseSummaryMap[id] = ExpenseExtras(
          expenseType: expenseType,
          totalAmount: order.amountDue,
          orderCount: 1,
        );
      } else {
        expenseSummaryMap[id] = current.copyWith(
          totalAmount: current.totalAmount + order.amountDue,
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
