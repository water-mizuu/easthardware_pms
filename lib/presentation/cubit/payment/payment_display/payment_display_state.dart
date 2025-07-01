part of 'payment_display_cubit.dart';

class PaymentDisplayState with EquatableMixin {
  const PaymentDisplayState({
    this.allPayments,
    this.filteredPayments,
    this.searchQuery = '',
    this.sortBy = PaymentDisplaySortBy.dateDescending,
    this.sortAscending = false,
  });

  PaymentDisplayState.empty()
      : allPayments = null,
        filteredPayments = null,
        searchQuery = '',
        sortBy = PaymentDisplaySortBy.dateDescending,
        sortAscending = false;

  final List<(Payment, String)>? allPayments;
  final List<(Payment, String)>? filteredPayments;
  final String searchQuery;
  final PaymentDisplaySortBy sortBy;
  final bool sortAscending;

  PaymentDisplayState Function({
    List<(Payment, String)>? allPayments,
    List<(Payment, String)>? filteredPayments,
    String searchQuery,
    PaymentDisplaySortBy sortBy,
    bool sortAscending,
  }) get copyWith {
    return ({
      Object? allPayments = undefined,
      Object? filteredPayments = undefined,
      Object? searchQuery = undefined,
      Object? sortBy = undefined,
      Object? sortAscending = undefined,
    }) {
      return PaymentDisplayState(
        allPayments: allPayments.or(this.allPayments),
        filteredPayments: filteredPayments.or(this.filteredPayments),
        searchQuery: searchQuery.or(this.searchQuery),
        sortBy: sortBy.or(this.sortBy),
        sortAscending: sortAscending.or(this.sortAscending),
      );
    };
  }

  @override
  List<Object?> get props => [
        allPayments,
        filteredPayments,
        searchQuery,
        sortBy,
        sortAscending,
      ];
}
