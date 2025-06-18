part of 'search_bloc.dart';

sealed class SearchEvent {}

final class SearchDependentsUpdated implements SearchEvent {
  const SearchDependentsUpdated({
    required this.products,
    required this.invoices,
    required this.orders,
  });

  final List<Product> products;
  final List<Invoice> invoices;
  final List<Order> orders;
}

final class SearchQueryUpdated implements SearchEvent {
  const SearchQueryUpdated(this.query);

  final String query;
}

final class SearchReset implements SearchEvent {
  const SearchReset();
}

final class SearchQuerySaved implements SearchEvent {
  const SearchQuerySaved();
}
