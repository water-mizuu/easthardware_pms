part of 'order_list_bloc.dart';

class OrderListState extends Equatable {
  const OrderListState({
    this.allOrders = const [],
    this.filteredOrders,
    this.status = DataStatus.initial,
    this.allOrderProducts = const [],
    this.allOrderItems = const [],
  });
  final List<Order> allOrders;
  final List<Order>? filteredOrders;
  final DataStatus status;
  final List<OrderProduct> allOrderProducts;
  final List<OrderItem> allOrderItems;

  OrderListState Function({
    List<Order> allOrders,
    List<Order>? filteredOrders,
    DataStatus status,
    List<OrderProduct> allOrderProducts,
    List<OrderItem> allOrderItems,
  }) get copyWith {
    return ({
      Object? allOrders = undefined,
      Object? filteredOrders = undefined,
      Object? status = undefined,
      Object? allOrderProducts = undefined,
      Object? allOrderItems = undefined,
    }) {
      return OrderListState(
        allOrders: allOrders.or(this.allOrders),
        filteredOrders: filteredOrders.or(this.filteredOrders),
        status: status.or(this.status),
        allOrderProducts: allOrderProducts.or(this.allOrderProducts),
        allOrderItems: allOrderItems.or(this.allOrderItems),
      );
    };
  }

  @override
  List<Object?> get props => [
        allOrders,
        filteredOrders,
        status,
        allOrderProducts,
        allOrderItems,
      ];
}
