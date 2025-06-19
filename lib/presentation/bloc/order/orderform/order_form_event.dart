part of 'order_form_bloc.dart';

abstract class OrderFormEvent extends Equatable {
  const OrderFormEvent();

  @override
  List<Object?> get props => [];
}

class PayeeNameChangedEvent extends OrderFormEvent {
  const PayeeNameChangedEvent(this.payeeName);
  final String payeeName;

  @override
  List<Object?> get props => [payeeName];
}

class ExpenseTypeChangedEvent extends OrderFormEvent {
  const ExpenseTypeChangedEvent(this.expenseType);
  final ExpenseType? expenseType;

  @override
  List<Object?> get props => [expenseType];
}

class OrderDateChangedEvent extends OrderFormEvent {
  const OrderDateChangedEvent(this.orderDate);
  final DateTime orderDate;

  @override
  List<Object?> get props => [orderDate];
}

class PaymentMethodChangedEvent extends OrderFormEvent {
  const PaymentMethodChangedEvent(this.paymentMethod);
  final PaymentMethod? paymentMethod;

  @override
  List<Object?> get props => [paymentMethod];
}

class ReferenceNumberChangedEvent extends OrderFormEvent {
  const ReferenceNumberChangedEvent(this.referenceNumber);
  final String referenceNumber;

  @override
  List<Object?> get props => [referenceNumber];
}

class MemoChangedEvent extends OrderFormEvent {
  const MemoChangedEvent(this.memo);
  final String memo;

  @override
  List<Object?> get props => [memo];
}

class ProductAddedEvent extends OrderFormEvent {
  const ProductAddedEvent();

  @override
  List<Object> get props => [];
}

class ProductRemovedEvent extends OrderFormEvent {
  const ProductRemovedEvent(this.index);
  final int index;

  @override
  List<Object?> get props => [index];
}

class ProductUpdatedEvent extends OrderFormEvent {
  const ProductUpdatedEvent(this.product, this.index);
  final FormProduct product;
  final int index;

  @override
  List<Object?> get props => [product, index];
}

class ProductSelectedEvent extends OrderFormEvent {
  const ProductSelectedEvent(this.product, this.index);
  final Product product;
  final int index;

  @override
  List<Object?> get props => [product, index];
}

class ClearProductsEvent extends OrderFormEvent {
  const ClearProductsEvent();

  @override
  List<Object?> get props => [];
}

class OrderItemAddedEvent extends OrderFormEvent {
  const OrderItemAddedEvent();

  @override
  List<Object?> get props => [];
}

class OrderItemRemovedEvent extends OrderFormEvent {
  const OrderItemRemovedEvent(this.index);
  final int index;

  @override
  List<Object?> get props => [index];
}

class OrderItemUpdatedEvent extends OrderFormEvent {
  const OrderItemUpdatedEvent(this.orderItem, this.index);
  final FormOrderItem orderItem;
  final int index;

  @override
  List<Object?> get props => [orderItem, index];
}

class ClearOrderItemsEvent extends OrderFormEvent {
  const ClearOrderItemsEvent();

  @override
  List<Object?> get props => [];
}

class FormSubmittedEvent extends OrderFormEvent {
  const FormSubmittedEvent();

  @override
  List<Object?> get props => [];
}

class SaveRestockOrderRequestEvent extends OrderFormEvent {
  const SaveRestockOrderRequestEvent({
    required this.creationDate,
    required this.creatorId,
    required this.id,
  });
  final DateTime creationDate;
  final dynamic creatorId;
  final int? id;

  @override
  List<Object?> get props => [creationDate, creatorId, id];
}

class SaveExpenseOrderRequestEvent extends OrderFormEvent {
  const SaveExpenseOrderRequestEvent({
    required this.creationDate,
    required this.creatorId,
    required this.id,
  });
  final DateTime creationDate;
  final dynamic creatorId;
  final int? id;

  @override
  List<Object?> get props => [creationDate, creatorId, id];
}
