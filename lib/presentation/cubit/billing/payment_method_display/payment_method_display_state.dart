part of 'payment_method_display_cubit.dart';

class PaymentMethodDisplayState with EquatableMixin {
  const PaymentMethodDisplayState({
    this.allPaymentMethods,
    this.filteredPaymentMethods,
    this.searchQuery = '',
    this.sortBy = PaymentMethodDisplaySortBy.nameAscending,
    this.sortAscending = true,
  });

  PaymentMethodDisplayState.empty()
      : allPaymentMethods = null,
        filteredPaymentMethods = null,
        searchQuery = '',
        sortBy = PaymentMethodDisplaySortBy.nameAscending,
        sortAscending = true;

  final List<PaymentMethod>? allPaymentMethods;
  final List<PaymentMethod>? filteredPaymentMethods;
  final String searchQuery;
  final PaymentMethodDisplaySortBy sortBy;
  final bool sortAscending;

  PaymentMethodDisplayState Function({
    List<PaymentMethod>? allPaymentMethods,
    List<PaymentMethod>? filteredPaymentMethods,
    String searchQuery,
    PaymentMethodDisplaySortBy sortBy,
    bool sortAscending,
  }) get copyWith {
    return ({
      Object? allPaymentMethods = undefined,
      Object? filteredPaymentMethods = undefined,
      Object? searchQuery = undefined,
      Object sortBy = undefined,
      Object? sortAscending = undefined,
    }) {
      return PaymentMethodDisplayState(
        allPaymentMethods: allPaymentMethods.or(this.allPaymentMethods),
        filteredPaymentMethods: filteredPaymentMethods.or(this.filteredPaymentMethods),
        searchQuery: searchQuery.or(this.searchQuery),
        sortBy: sortBy.or(this.sortBy),
        sortAscending: sortAscending.or(this.sortAscending),
      );
    };
  }

  @override
  List<Object?> get props => [
        allPaymentMethods,
        filteredPaymentMethods,
        searchQuery,
        sortBy,
        sortAscending,
      ];
}
