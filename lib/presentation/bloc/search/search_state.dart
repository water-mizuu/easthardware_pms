import 'package:easthardware_pms/domain/models/invoice.dart';
import 'package:easthardware_pms/domain/models/order.dart';
import 'package:easthardware_pms/domain/models/product.dart';
import 'package:easthardware_pms/utils/undefined.dart';

final class SearchState {
  const SearchState({
    required this.allProducts,
    this.query = '',
    this.results = const SearchResults.empty(),
    this.isLoading = false,
    this.errorMessage,
  });

  final List<Product> allProducts;
  final String query;
  final SearchResults results;
  final bool isLoading;
  final String? errorMessage;

  SearchState Function({
    List<Product> allProducts,
    String query,
    SearchResults results,
    bool isLoading,
    String? errorMessage,
  }) get copyWith {
    return ({
      Object? allProducts = undefined,
      Object? query = undefined,
      Object? results = undefined,
      Object? isLoading = undefined,
      Object? errorMessage = undefined,
    }) {
      return SearchState(
        allProducts: allProducts.or(this.allProducts),
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

  final List<(Product, double)> products;
  final List<Invoice> invoices;
  final List<Order> orders;
}
