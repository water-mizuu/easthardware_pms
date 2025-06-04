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
  const AddOrderEvent(this.order);
  final Order order;

  @override
  List<Object> get props => [order];
}

class ChangeRowsPerPageEvent extends OrderListEvent {
  const ChangeRowsPerPageEvent(this.rowsPerPage);
  final int rowsPerPage;
}

class UpdateOrderEvent extends OrderListEvent {
  const UpdateOrderEvent(this.order);
  final Order order;

  @override
  List<Object> get props => [order];
}

class DeleteOrderEvent extends OrderListEvent {
  final Order order;

  const DeleteOrderEvent(this.order);

  @override
  List<Object> get props => [order];
}
