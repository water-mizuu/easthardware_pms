part of 'order_list_bloc.dart';

class OrderListState extends Equatable {
  final List<Order> allOrders;
  final List<Order>? filteredOrders;
  final List<Order> deliveredOrders;
  final List<Order> pendingOrders;
  final DataStatus status;

  const OrderListState({
    this.allOrders = const [],
    this.filteredOrders,
    this.deliveredOrders = const [],
    this.pendingOrders = const [],
    this.status = DataStatus.initial,
  });

  OrderListState copyWith({
    List<Order>? allOrders,
    List<Order>? filteredOrders,
    List<Order>? deliveredOrders,
    List<Order>? pendingOrders,
    DataStatus? status,
  }) {
    return OrderListState(
      allOrders: allOrders ?? this.allOrders,
      filteredOrders: filteredOrders ?? this.filteredOrders,
      deliveredOrders: deliveredOrders ?? this.deliveredOrders,
      pendingOrders: pendingOrders ?? this.pendingOrders,
      status: status ?? this.status,
    );
  }

  @override
  List<Object> get props => [
        allOrders,
        filteredOrders ?? [],
        deliveredOrders,
        pendingOrders,
        status,
      ];
}
