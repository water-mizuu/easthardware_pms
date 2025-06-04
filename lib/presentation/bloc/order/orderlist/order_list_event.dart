part of 'order_list_bloc.dart';

sealed class OrderListEvent extends Equatable {
  const OrderListEvent();

  @override
  List<Object> get props => [];
}

class FetchAllOrdersEvent extends OrderListEvent {
  const FetchAllOrdersEvent();
}

class AddOrderEvent extends OrderListEvent {
  final Order order;

  const AddOrderEvent(this.order);

  @override
  List<Object> get props => [order];
}

class UpdateOrderEvent extends OrderListEvent {
  final Order order;

  const UpdateOrderEvent(this.order);

  @override
  List<Object> get props => [order];
}

class DeleteOrderEvent extends OrderListEvent {
  final Order order;

  const DeleteOrderEvent(this.order);

  @override
  List<Object> get props => [order];
}
