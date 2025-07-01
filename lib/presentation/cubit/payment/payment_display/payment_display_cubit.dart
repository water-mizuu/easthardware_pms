import 'dart:math';

import 'package:bloc/bloc.dart';
import 'package:easthardware_pms/domain/enums/enums.dart';
import 'package:easthardware_pms/domain/models/payment.dart';
import 'package:easthardware_pms/utils/levenshtein.dart';
import 'package:easthardware_pms/utils/undefined.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'payment_display_state.dart';

class PaymentDisplayCubit extends Cubit<PaymentDisplayState> {
  PaymentDisplayCubit() : super(PaymentDisplayState.empty()) {
    // Initialize any listeners or subscriptions if needed
  }

  // Method to update the list of payments
  void updatePayments(List<(Payment, String)> payments) {
    if (payments.isEmpty) {
      emit(state.copyWith(
        searchQuery: '',
        filteredPayments: null,
        allPayments: null,
      ));
      return;
    }

    emit(state.copyWith(allPayments: payments));
    _processQuery();
  }

  // Method to update search query
  void search(String query) {
    final allPayments = state.allPayments;
    if (allPayments == null || allPayments.isEmpty) {
      emit(state.copyWith(
        searchQuery: query,
        allPayments: null,
      ));
      return;
    }

    emit(state.copyWith(searchQuery: query));
    _processQuery();
  }

  // Method to update sort criteria
  void sort(PaymentDisplaySortBy sortBy) {
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
  PaymentDisplaySortBy _getSortTypeBasedOnDirection(
    PaymentDisplaySortBy sortType,
    bool ascending,
  ) {
    switch (sortType) {
      case PaymentDisplaySortBy.dateAscending:
      case PaymentDisplaySortBy.dateDescending:
        return ascending ? PaymentDisplaySortBy.dateAscending : PaymentDisplaySortBy.dateDescending;

      case PaymentDisplaySortBy.amountAscending:
      case PaymentDisplaySortBy.amountDescending:
        return ascending
            ? PaymentDisplaySortBy.amountAscending
            : PaymentDisplaySortBy.amountDescending;

      case PaymentDisplaySortBy.referenceAscending:
      case PaymentDisplaySortBy.referenceDescending:
        return ascending
            ? PaymentDisplaySortBy.referenceAscending
            : PaymentDisplaySortBy.referenceDescending;

      default:
        return PaymentDisplaySortBy.dateDescending;
    }
  }

  // Process the query and filter/sort the payments
  void _processQuery() {
    final allPayments = state.allPayments;
    if (allPayments == null || allPayments.isEmpty) {
      emit(state.copyWith(filteredPayments: null));
      return;
    }

    // First, filter by search query if needed
    final searchQuery = state.searchQuery.trim().toLowerCase();
    var filteredPayments = allPayments;

    if (searchQuery.isNotEmpty) {
      filteredPayments = allPayments.where((payment) {
        final reference = payment.$1.referenceNumber.toLowerCase();
        final amount = payment.$1.amount.toString().toLowerCase();
        final date = payment.$1.paymentDate.toString().toLowerCase();

        // Simple contains check
        if (reference.contains(searchQuery) ||
            amount.contains(searchQuery) ||
            date.contains(searchQuery)) {
          return true;
        }

        // Levenshtein distance check for fuzzy matching
        final distance = Levenshtein.distance(reference, searchQuery);
        final maxDistance = max(1, searchQuery.length ~/ 3);
        return distance <= maxDistance;
      }).toList();
    }

    // Then sort based on the selected sort criteria
    _sortPayments(filteredPayments);

    emit(state.copyWith(filteredPayments: filteredPayments));
  }

  // Helper method to sort payments
  void _sortPayments(List<(Payment, String)> payments) {
    switch (state.sortBy) {
      case PaymentDisplaySortBy.dateAscending:
        payments.sort((a, b) => a.$1.paymentDate.compareTo(b.$1.paymentDate));
        break;
      case PaymentDisplaySortBy.dateDescending:
        payments.sort((a, b) => b.$1.paymentDate.compareTo(a.$1.paymentDate));
        break;
      case PaymentDisplaySortBy.customerAscending:
        payments.sort((a, b) => a.$2.compareTo(b.$2));
        break;
      case PaymentDisplaySortBy.customerDescending:
        payments.sort((a, b) => b.$2.compareTo(a.$2));
        break;
      case PaymentDisplaySortBy.amountAscending:
        payments.sort((a, b) => a.$1.amount.compareTo(b.$1.amount));
        break;
      case PaymentDisplaySortBy.amountDescending:
        payments.sort((a, b) => b.$1.amount.compareTo(a.$1.amount));
        break;
      case PaymentDisplaySortBy.referenceAscending:
        payments.sort((a, b) => a.$1.referenceNumber.compareTo(b.$1.referenceNumber));
        break;
      case PaymentDisplaySortBy.referenceDescending:
        payments.sort((a, b) => b.$1.referenceNumber.compareTo(a.$1.referenceNumber));
        break;
    }
  }
}
