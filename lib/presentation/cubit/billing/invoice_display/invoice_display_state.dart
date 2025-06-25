part of 'invoice_display_cubit.dart';

class InvoiceDisplayState with EquatableMixin {
  const InvoiceDisplayState({
    this.allInvoices,
    this.filteredInvoices,
    this.searchQuery = '',
    this.sortBy = InvoiceDisplaySortBy.invoiceDateDescending,
    this.sortAscending = false,
  });

  final List<Invoice>? allInvoices;
  final List<Invoice>? filteredInvoices;
  final String searchQuery;
  final InvoiceDisplaySortBy sortBy;
  final bool sortAscending;

  InvoiceDisplayState copyWith({
    List<Invoice>? allInvoices,
    List<Invoice>? filteredInvoices,
    String? searchQuery,
    InvoiceDisplaySortBy? sortBy,
    bool? sortAscending,
  }) {
    return InvoiceDisplayState(
      allInvoices: allInvoices ?? this.allInvoices,
      filteredInvoices: filteredInvoices ?? this.filteredInvoices,
      searchQuery: searchQuery ?? this.searchQuery,
      sortBy: sortBy ?? this.sortBy,
      sortAscending: sortAscending ?? this.sortAscending,
    );
  }

  @override
  List<Object?> get props => [
        allInvoices,
        filteredInvoices,
        searchQuery,
        sortBy,
        sortAscending,
      ];
}
