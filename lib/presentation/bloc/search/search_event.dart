part of 'search_bloc.dart';

sealed class SearchEvent {}

final class SearchDependentsUpdated implements SearchEvent {
  const SearchDependentsUpdated({
    required this.products,
    required this.invoices,
    required this.orders,
    required this.expenseTypes,
  });

  final List<Product> products;
  final List<Invoice> invoices;
  final List<Order> orders;
  final List<ExpenseType> expenseTypes;
}

final class SearchQueryUpdated implements SearchEvent {
  const SearchQueryUpdated(this.query);

  final String query;
}

final class SearchLimitUpdated implements SearchEvent {
  const SearchLimitUpdated(this.limit);

  final int limit;
}

final class SearchReset implements SearchEvent {
  const SearchReset();
}
