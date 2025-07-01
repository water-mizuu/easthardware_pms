part of 'search_bloc.dart';

final class SearchState {
  const SearchState({
    required this.allProducts,
    required this.allInvoices,
    required this.allOrders,
    required this.allExpenseTypes,
    this.query = '',
    this.limit = 20,
    this.results = const SearchResults.empty(),
    this.isLoading = false,
    this.errorMessage,
  });

  final List<Product> allProducts;
  final List<Invoice> allInvoices;
  final List<Order> allOrders;
  final List<ExpenseType> allExpenseTypes;

  final String query;
  final int limit;
  final SearchResults results;
  final bool isLoading;
  final String? errorMessage;

  SearchState Function({
    List<Product> allProducts,
    List<Invoice> allInvoices,
    List<Order> allOrders,
    List<ExpenseType> allExpenseTypes,
    String query,
    int limit,
    List<String> searchHistory,
    SearchResults results,
    bool isLoading,
    String? errorMessage,
  }) get copyWith {
    return ({
      Object? allProducts = undefined,
      Object? allInvoices = undefined,
      Object? allOrders = undefined,
      Object? allExpenseTypes = undefined,
      Object? query = undefined,
      Object? limit = undefined,
      Object? searchHistory = undefined,
      Object? results = undefined,
      Object? isLoading = undefined,
      Object? errorMessage = undefined,
    }) {
      return SearchState(
        allProducts: allProducts.or(this.allProducts),
        allInvoices: allInvoices.or(this.allInvoices),
        allOrders: allOrders.or(this.allOrders),
        allExpenseTypes: allExpenseTypes.or(this.allExpenseTypes),
        query: query.or(this.query),
        limit: limit.or(this.limit),
        results: results.or(this.results),
        isLoading: isLoading.or(this.isLoading),
        errorMessage: errorMessage.or(this.errorMessage),
      );
    };
  }
}

final class SearchResults {
  const SearchResults({
    required this.products,
    required this.invoices,
    required this.orders,
  });
  const SearchResults.empty()
      : products = const [],
        invoices = const [],
        orders = const [];

  final List<Product> products;
  final List<Invoice> invoices;
  final List<Order> orders;
}
