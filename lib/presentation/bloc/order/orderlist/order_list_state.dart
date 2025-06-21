part of 'order_list_bloc.dart';

class OrderListState extends Equatable {
  const OrderListState({
    this.allOrders = const [],
    this.filteredOrders,
    this.status = DataStatus.initial,
  });
  final List<Order> allOrders;
  final List<Order>? filteredOrders;
  final DataStatus status;

  OrderListState copyWith({
    List<Order>? allOrders,
    List<Order>? filteredOrders,
    DataStatus? status,
  }) {
    return OrderListState(
      allOrders: allOrders ?? this.allOrders,
      filteredOrders: filteredOrders ?? this.filteredOrders,
      status: status ?? this.status,
    );
  }

  @override
  List<Object> get props => [
        allOrders,
        filteredOrders ?? [],
        status,
      ];
}
