part of 'order_list_bloc.dart';

sealed class OrderListEvent extends Equatable {
  const OrderListEvent();

  @override
  List<Object> get props => [];
}

class FetchAllOrdersEvent extends OrderListEvent {
  const FetchAllOrdersEvent();
}

class FetchOrderProductsEvent extends OrderListEvent {
  const FetchOrderProductsEvent();
}

class FetchOrderItemsEvent extends OrderListEvent {
  const FetchOrderItemsEvent();
}

class AddProductOrderEvent extends OrderListEvent {
  const AddProductOrderEvent(this.order, this.products);
  final Order order;
  final List<OrderProduct> products;

  @override
  List<Object> get props => [order, products];
}

class AddItemOrderEvent extends OrderListEvent {
  const AddItemOrderEvent(this.order, this.items);

  final Order order;
  final List<OrderItem> items;

  @override
  List<Object> get props => [order, items];
}

class ChangeRowsPerPageEvent extends OrderListEvent {
  const ChangeRowsPerPageEvent(this.rowsPerPage);
  final int rowsPerPage;
}

class UpdateRestockOrderEvent extends OrderListEvent {
  const UpdateRestockOrderEvent(this.order, this.products);
  final Order order;
  final List<OrderProduct> products;

  @override
  List<Object> get props => [order, products];
}

class DeleteOrderEvent extends OrderListEvent {
  const DeleteOrderEvent(this.order);
  final Order order;

  @override
  List<Object> get props => [order];
}

class UpdateItemOrderEvent extends OrderListEvent {
  const UpdateItemOrderEvent(this.order, this.orderItems);
  final Order order;
  final List<OrderItem> orderItems;

  @override
  List<Object> get props => [order, orderItems];
}
