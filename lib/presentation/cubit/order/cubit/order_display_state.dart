part of 'order_display_cubit.dart';

class OrderDisplayState extends Equatable {
  const OrderDisplayState({
    this.searchQuery = '',
    this.allOrders,
    this.filteredOrders,
    this.sortBy = OrderDisplaySortBy.orderDateDescending,
    this.sortAscending = false,
  });

  final String searchQuery;
  final List<Order>? allOrders;
  final List<Order>? filteredOrders;
  final OrderDisplaySortBy sortBy;
  final bool sortAscending;

  OrderDisplayState copyWith({
    String? searchQuery,
    List<Order>? allOrders,
    List<Order>? filteredOrders,
    OrderDisplaySortBy? sortBy,
    bool? sortAscending,
  }) {
    return OrderDisplayState(
      searchQuery: searchQuery ?? this.searchQuery,
      allOrders: allOrders ?? this.allOrders,
      filteredOrders: filteredOrders ?? this.filteredOrders,
      sortBy: sortBy ?? this.sortBy,
      sortAscending: sortAscending ?? this.sortAscending,
    );
  }

  @override
  List<Object?> get props => [
        searchQuery,
        allOrders,
        filteredOrders,
        sortBy,
        sortAscending,
      ];
}
