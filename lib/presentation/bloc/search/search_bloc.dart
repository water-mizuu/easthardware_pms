import 'dart:async';
import 'dart:math';

import 'package:dart_bloc_concurrency/dart_bloc_concurrency.dart';
import 'package:easthardware_pms/domain/models/expense_type.dart';
import 'package:easthardware_pms/domain/models/invoice.dart';
import 'package:easthardware_pms/domain/models/order.dart';
import 'package:easthardware_pms/domain/models/product.dart';
import 'package:easthardware_pms/utils/duration.dart';
import 'package:easthardware_pms/utils/levenshtein.dart';
import 'package:easthardware_pms/utils/undefined.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

part 'search_event.dart';
part 'search_state.dart';

class SearchBloc extends Bloc<SearchEvent, SearchState> {
  SearchBloc()
      : super(const SearchState(
          allProducts: [],
          allInvoices: [],
          allOrders: [],
          allExpenseTypes: [],
        )) {
    on<SearchDependentsUpdated>(_onDependentsUpdated);
    on<SearchQueryUpdated>(_onQueryUpdated, transformer: debounce(0.ms));
    on<SearchLimitUpdated>(_onSearchLimitUpdated);
    on<SearchReset>(_onSearchReset);
  }

  Future<List<Product>> _processProduct(String query) {
    return Levenshtein.rankItems(
      state.allProducts,
      query,
      (p) => {
        p.id?.toString(),
        p.sku,
        p.name,
        p.categoryName,
        p.description,
      } //
          .whereType<String>(),
    ).then((p) => p.sublist(0, min(p.length, state.limit)));
  }

  Future<List<Invoice>> _processInvoice(String query) {
    /// For now, we will just search by customer name and reference number.
    ///   Eventually, this should include stuff like product names, invoice numbers, etc.
    return Levenshtein.rankItems(
      state.allInvoices,
      query,
      (i) => {
        i.id?.toString(),
        i.customerName,
        i.referenceNumber,
        i.customerName,
        i.referenceNumber,
        i.memo,
      }.whereType<String>(),
    ).then((p) => p.sublist(0, min(p.length, state.limit)));
  }

  Future<List<Order>> _processOrder(String query) {
    final expenseTypeCache = <int, String>{};

    /// For now, we will just search by customer name and reference number.
    ///   Eventually, this should include stuff like product names, order numbers, etc.
    return Levenshtein.rankItems(
      state.allOrders,
      query,
      (o) => {
        o.id?.toString(),
        o.referenceNumber,
        DateFormat('yyyy-MM-dd').format(o.orderDate),
        o.payeeName,
        expenseTypeCache.putIfAbsent(
          o.expenseType,
          () => state.allExpenseTypes
              .firstWhere(
                (et) => et.id == o.expenseType,
                orElse: () => const ExpenseType(name: '-'),
              )
              .name,
        ),
        o.memo,
      }.whereType<String>(),
    ).then((p) => p.sublist(0, min(p.length, state.limit)));
  }

  Future<void> _onDependentsUpdated(
    SearchDependentsUpdated event,
    Emitter<SearchState> emit,
  ) async {
    emit(state.copyWith(
      allProducts: event.products,
      allInvoices: event.invoices,
      allOrders: event.orders,
      allExpenseTypes: event.expenseTypes,
    ));

    if (state.query.isNotEmpty) {
      /// If the query is not empty, we need to re-process the results.
      add(SearchQueryUpdated(state.query));
    } else {
      /// If the query is empty, we reset the results.
      add(const SearchReset());
    }
  }

  Future<void> _onSearchLimitUpdated(SearchLimitUpdated event, Emitter<SearchState> emit) async {
    emit(state.copyWith(limit: event.limit));

    if (state.query.isNotEmpty) {
      /// If the query is not empty, we need to re-process the results.
      add(SearchQueryUpdated(state.query));
    } else {
      /// If the query is empty, we reset the results.
      add(const SearchReset());
    }
  }

  Future<void> _onQueryUpdated(SearchQueryUpdated event, Emitter<SearchState> emit) async {
    final query = event.query.trim().toLowerCase();

    emit(state.copyWith(query: query));

    /// Do the search logic here.
    ///   For now only search the products.
    if (query.isEmpty) {
      add(const SearchReset());
      return;
    }

    emit(state.copyWith(isLoading: true, errorMessage: null));
    try {
      final (products, invoices, orders) = await (
        _processProduct(query),
        _processInvoice(query),
        _processOrder(query),
      ).wait; // Wait for all three processes to complete

      final results = SearchResults(
        products: products,
        invoices: invoices,
        orders: orders,
      );

      emit(state.copyWith(results: results));
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    } finally {
      emit(state.copyWith(isLoading: false));
    }
  }

  Future<void> _onSearchReset(SearchReset event, Emitter<SearchState> emit) async {
    emit(state.copyWith(
      query: '',
      results: SearchResults(
        products: state.allProducts.toList().take(state.limit).toList(),
        invoices: state.allInvoices.toList().take(state.limit).toList(),
        orders: state.allOrders.toList().take(state.limit).toList(),
      ),
    ));
  }
}
