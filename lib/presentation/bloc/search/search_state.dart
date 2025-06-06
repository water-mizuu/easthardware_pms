part of 'search_bloc.dart';

final class SearchState {
  const SearchState({
    required this.allProducts,
    required this.allInvoices,
    required this.allOrders,
    this.query = '',
    this.results = const SearchResults.empty(),
    this.isLoading = false,
    this.errorMessage,
  });

  final List<Product> allProducts;
  final List<Invoice> allInvoices;
  final List<Order> allOrders;

  final String query;
  final SearchResults results;
  final bool isLoading;
  final String? errorMessage;

  SearchState Function({
    List<Product> allProducts,
    List<Invoice> allInvoices,
    List<Order> allOrders,
    String query,
    SearchResults results,
    bool isLoading,
    String? errorMessage,
  }) get copyWith {
    return ({
      Object? allProducts = undefined,
      Object? allInvoices = undefined,
      Object? allOrders = undefined,
      Object? query = undefined,
      Object? results = undefined,
      Object? isLoading = undefined,
      Object? errorMessage = undefined,
    }) {
      return SearchState(
        allProducts: allProducts.or(this.allProducts),
        allInvoices: allInvoices.or(this.allInvoices),
        allOrders: allOrders.or(this.allOrders),
        query: query.or(this.query),
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
