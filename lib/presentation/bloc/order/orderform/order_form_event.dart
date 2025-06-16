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
  final int expenseType;

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
  final int paymentMethod;

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

class AmountPaidChangedEvent extends OrderFormEvent {
  const AmountPaidChangedEvent(this.amountPaid);
  final double amountPaid;

  @override
  List<Object?> get props => [amountPaid];
}

class PaymentDateChangedEvent extends OrderFormEvent {
  const PaymentDateChangedEvent(this.paymentDate);
  final DateTime paymentDate;

  @override
  List<Object?> get props => [paymentDate];
}

class ProductAddedEvent extends OrderFormEvent {}

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

class FormButtonPressedEvent extends OrderFormEvent {}

class ClearProductsEvent extends OrderFormEvent {}

class FormSubmittedEvent extends OrderFormEvent {}

class SaveOrderRequestEvent extends OrderFormEvent {
  const SaveOrderRequestEvent({
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
