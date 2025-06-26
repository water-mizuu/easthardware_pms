import 'dart:math';

import 'package:bloc/bloc.dart';
import 'package:easthardware_pms/domain/models/order.dart';
import 'package:easthardware_pms/presentation/cubit/order/cubit/order_display_enum.dart';
import 'package:easthardware_pms/utils/levenshtein.dart';
import 'package:equatable/equatable.dart';

part 'order_display_state.dart';

class OrderDisplayCubit extends Cubit<OrderDisplayState> {
  OrderDisplayCubit() : super(const OrderDisplayState());

  // Method to update the list of orders
  void updateOrders(List<Order> orders) {
    if (orders.isEmpty) {
      emit(state.copyWith(
        searchQuery: '',
        filteredOrders: null,
        allOrders: null,
      ));
      return;
    }

    emit(state.copyWith(allOrders: orders));
    _processQuery();
  }

  // Method to update search query
  void search(String query) {
    final allOrders = state.allOrders;
    if (allOrders == null || allOrders.isEmpty) {
      emit(state.copyWith(
        searchQuery: query,
        allOrders: null,
      ));
      return;
    }

    emit(state.copyWith(searchQuery: query));
    _processQuery();
  }

  // Method to update sort criteria
  void sort(OrderDisplaySortBy sortBy) {
    // Check if we're selecting the same sort type that's already active
    if (state.sortBy == sortBy) {
      // Toggle the sort direction if the same sort type is selected again
      emit(state.copyWith(sortAscending: !state.sortAscending));

      // Determine the appropriate sort type based on the field and direction
      final newSortBy = _getSortTypeBasedOnDirection(sortBy, !state.sortAscending);

      emit(state.copyWith(sortBy: newSortBy));
    } else {
      // Default to ascending order for new sort type
      emit(state.copyWith(
        sortBy: sortBy,
        sortAscending: true,
      ));
    }

    _processQuery();
  }

  // Helper method to get the correct sort type based on direction
  OrderDisplaySortBy _getSortTypeBasedOnDirection(
    OrderDisplaySortBy currentSort,
    bool ascending,
  ) {
    switch (currentSort) {
      case OrderDisplaySortBy.orderDateAscending:
      case OrderDisplaySortBy.orderDateDescending:
        return ascending
            ? OrderDisplaySortBy.orderDateDescending
            : OrderDisplaySortBy.orderDateAscending;

      case OrderDisplaySortBy.idAscending:
      case OrderDisplaySortBy.idDescending:
        return ascending ? OrderDisplaySortBy.idDescending : OrderDisplaySortBy.idAscending;

      case OrderDisplaySortBy.payeeNameAscending:
      case OrderDisplaySortBy.payeeNameDescending:
        return ascending
            ? OrderDisplaySortBy.payeeNameDescending
            : OrderDisplaySortBy.payeeNameAscending;

      case OrderDisplaySortBy.expenseTypeAscending:
      case OrderDisplaySortBy.expenseTypeDescending:
        return ascending
            ? OrderDisplaySortBy.expenseTypeDescending
            : OrderDisplaySortBy.expenseTypeAscending;

      case OrderDisplaySortBy.amountDueAscending:
      case OrderDisplaySortBy.amountDueDescending:
        return ascending
            ? OrderDisplaySortBy.amountDueDescending
            : OrderDisplaySortBy.amountDueAscending;
    }
  }

  // Process the query and filter/sort the orders
  void _processQuery() {
    emit(state.copyWith(filteredOrders: null));

    final allOrders = state.allOrders;
    if (allOrders == null || allOrders.isEmpty) {
      emit(state.copyWith(filteredOrders: null));
      return;
    }

    // First, filter by search query if needed
    final searchQuery = state.searchQuery.trim().toLowerCase();
    var filteredOrders = allOrders;

    if (searchQuery.isNotEmpty) {
      filteredOrders = allOrders.where((order) {
        final orderId = order.id.toString().toLowerCase();
        final payeeName = order.payeeName.toLowerCase();
        final amountDue = order.amountDue.toString().toLowerCase();
        final expenseType = order.expenseType.toString().toLowerCase();

        // Simple contains check
        if (orderId.contains(searchQuery) ||
            payeeName.contains(searchQuery) ||
            amountDue.contains(searchQuery) ||
            expenseType.contains(searchQuery)) {
          return true;
        }

        // Levenshtein distance check for fuzzy matching
        final distanceOrderId = Levenshtein.distance(orderId, searchQuery);
        final distancePayeeName = Levenshtein.distance(payeeName, searchQuery);
        final maxDistance = max(1, searchQuery.length ~/ 3);

        return distanceOrderId <= maxDistance || distancePayeeName <= maxDistance;
      }).toList();
    }

    // Sort based on the selected sort criteria directly using the enum's properties
    filteredOrders = _sortOrders(filteredOrders);

    emit(state.copyWith(filteredOrders: filteredOrders));
  }

  // Helper method to sort orders based on the enum type
  List<Order> _sortOrders(List<Order> orders) {
    final sortedOrders = List<Order>.from(orders);
    sortedOrders.sort(state.sortBy.compareOrders);
    return sortedOrders;
  }
}
