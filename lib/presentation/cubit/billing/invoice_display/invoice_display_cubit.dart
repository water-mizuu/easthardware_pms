import 'dart:math';

import 'package:bloc/bloc.dart';
import 'package:easthardware_pms/domain/enums/enums.dart';
import 'package:easthardware_pms/domain/models/invoice.dart';
import 'package:easthardware_pms/utils/levenshtein.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'invoice_display_state.dart';

class InvoiceDisplayCubit extends Cubit<InvoiceDisplayState> {
  InvoiceDisplayCubit() : super(const InvoiceDisplayState()) {
    // Initialize any listeners or subscriptions if needed
  }

  // Method to update the list of invoices
  void updateInvoices(List<Invoice> invoices) {
    if (invoices.isEmpty) {
      emit(state.copyWith(
        searchQuery: '',
        filteredInvoices: null,
        allInvoices: null,
      ));
      return;
    }

    emit(state.copyWith(allInvoices: invoices));
    _processQuery();
  }

  // Method to update search query
  void search(String query) {
    final allInvoices = state.allInvoices;
    if (allInvoices == null || allInvoices.isEmpty) {
      emit(state.copyWith(
        searchQuery: query,
        allInvoices: null,
      ));
      return;
    }

    emit(state.copyWith(searchQuery: query));
    _processQuery();
  }

  // Method to update sort criteria
  void sort(InvoiceDisplaySortBy sortBy) {
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
  InvoiceDisplaySortBy _getSortTypeBasedOnDirection(
    InvoiceDisplaySortBy currentSort,
    bool ascending,
  ) {
    switch (currentSort) {
      case InvoiceDisplaySortBy.invoiceDateAscending:
      case InvoiceDisplaySortBy.invoiceDateDescending:
        return ascending
            ? InvoiceDisplaySortBy.invoiceDateDescending
            : InvoiceDisplaySortBy.invoiceDateAscending;

      case InvoiceDisplaySortBy.numberAscending:
      case InvoiceDisplaySortBy.numberDescending:
        return ascending
            ? InvoiceDisplaySortBy.numberDescending
            : InvoiceDisplaySortBy.numberAscending;

      case InvoiceDisplaySortBy.customerAscending:
      case InvoiceDisplaySortBy.customerDescending:
        return ascending
            ? InvoiceDisplaySortBy.customerDescending
            : InvoiceDisplaySortBy.customerAscending;

      case InvoiceDisplaySortBy.totalAscending:
      case InvoiceDisplaySortBy.totalDescending:
        return ascending
            ? InvoiceDisplaySortBy.totalDescending
            : InvoiceDisplaySortBy.totalAscending;

      case InvoiceDisplaySortBy.statusAscending:
      case InvoiceDisplaySortBy.statusDescending:
        return ascending
            ? InvoiceDisplaySortBy.statusDescending
            : InvoiceDisplaySortBy.statusAscending;
      default:
        return currentSort;
    }
  }

  // Process the query and filter/sort the invoices
  void _processQuery() {
    emit(state.copyWith(filteredInvoices: null));

    final allInvoices = state.allInvoices;
    if (allInvoices == null || allInvoices.isEmpty) {
      emit(state.copyWith(filteredInvoices: null));
      return;
    }

    // First, filter by search query if needed
    final searchQuery = state.searchQuery.trim().toLowerCase();
    var filteredInvoices = allInvoices;

    if (searchQuery.isNotEmpty) {
      filteredInvoices = allInvoices.where((invoice) {
        final invoiceNumber = invoice.id.toString().toLowerCase();
        final customerName = invoice.customerName.toLowerCase();
        final total = invoice.amountDue.toString().toLowerCase();

        // Simple contains check
        if (invoiceNumber.contains(searchQuery) ||
            customerName.contains(searchQuery) ||
            total.contains(searchQuery)) {
          return true;
        }

        // Levenshtein distance check for fuzzy matching
        final distanceInvoiceNumber = Levenshtein.distance(invoiceNumber, searchQuery);
        final distanceCustomerName = Levenshtein.distance(customerName, searchQuery);
        final maxDistance = max(1, searchQuery.length ~/ 3);

        return distanceInvoiceNumber <= maxDistance || distanceCustomerName <= maxDistance;
      }).toList();
    }

    // Sort based on the selected sort criteria directly using the enum's properties
    filteredInvoices = _sortInvoices(filteredInvoices);

    emit(state.copyWith(filteredInvoices: filteredInvoices));
  }

  // Helper method to sort invoices based on the enum type
  List<Invoice> _sortInvoices(List<Invoice> invoices) {
    final sortedInvoices = List<Invoice>.from(invoices);
    switch (state.sortBy) {
      case InvoiceDisplaySortBy.invoiceDateAscending:
        sortedInvoices.sort((a, b) => a.invoiceDate.compareTo(b.invoiceDate));
        break;
      case InvoiceDisplaySortBy.invoiceDateDescending:
        sortedInvoices.sort((a, b) => b.invoiceDate.compareTo(a.invoiceDate));
        break;
      case InvoiceDisplaySortBy.numberAscending:
        sortedInvoices.sort((a, b) => a.id!.compareTo(b.id!));
        break;
      case InvoiceDisplaySortBy.numberDescending:
        sortedInvoices.sort((a, b) => b.id!.compareTo(a.id!));
        break;
      case InvoiceDisplaySortBy.customerAscending:
        sortedInvoices.sort((a, b) => a.customerName.compareTo(b.customerName));
        break;
      case InvoiceDisplaySortBy.customerDescending:
        sortedInvoices.sort((a, b) => b.customerName.compareTo(a.customerName));
        break;
      case InvoiceDisplaySortBy.totalAscending:
        sortedInvoices.sort((a, b) => a.amountDue.compareTo(b.amountDue));
        break;
      case InvoiceDisplaySortBy.totalDescending:
        sortedInvoices.sort((a, b) => b.amountDue.compareTo(a.amountDue));
        break;
      case InvoiceDisplaySortBy.statusAscending:
        final paidInvoices = sortedInvoices.where((i) => i.paymentDate != null).toList();
        final unpaidInvoices = sortedInvoices.where((i) => i.paymentDate == null).toList();
        paidInvoices.sort((a, b) => a.paymentDate!.compareTo(b.paymentDate!));
        unpaidInvoices.sort((a, b) => a.dueDate.compareTo(b.dueDate));
        return [...unpaidInvoices, ...paidInvoices];
      case InvoiceDisplaySortBy.statusDescending:
        final paidInvoices = sortedInvoices.where((i) => i.paymentDate != null).toList();
        final unpaidInvoices = sortedInvoices.where((i) => i.paymentDate == null).toList();
        paidInvoices.sort((a, b) => b.paymentDate!.compareTo(a.paymentDate!));
        unpaidInvoices.sort((a, b) => b.dueDate.compareTo(a.dueDate));
        return [...paidInvoices, ...unpaidInvoices];
    }
    return sortedInvoices;
  }
}
