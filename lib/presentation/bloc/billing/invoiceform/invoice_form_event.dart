part of 'invoice_form_bloc.dart';

sealed class InvoiceFormEvent extends Equatable {
  const InvoiceFormEvent();

  @override
  List<Object?> get props => [];
}

class CustomerNameChangedEvent extends InvoiceFormEvent {
  const CustomerNameChangedEvent(this.customerName);
  final String customerName;

  @override
  List<Object> get props => [customerName];
}

class InvoiceDateChangedEvent extends InvoiceFormEvent {
  const InvoiceDateChangedEvent(this.invoiceDate);
  final DateTime invoiceDate;

  @override
  List<Object> get props => [invoiceDate];
}

class DueDateChangedEvent extends InvoiceFormEvent {
  const DueDateChangedEvent(this.dueDate);
  final DateTime dueDate;

  @override
  List<Object> get props => [dueDate];
}

class MemoChangedEvent extends InvoiceFormEvent {
  const MemoChangedEvent(this.memo);
  final String memo;

  @override
  List<Object> get props => [memo];
}

class DiscountChangedEvent extends InvoiceFormEvent {
  const DiscountChangedEvent(this.discount);
  final double discount;

  @override
  List<Object> get props => [discount];
}

class DiscountTypeChangedEvent extends InvoiceFormEvent {
  const DiscountTypeChangedEvent(this.discountType);
  final DiscountType discountType;

  @override
  List<Object> get props => [discountType];
}

class ProductAddedEvent extends InvoiceFormEvent {
  const ProductAddedEvent();

  @override
  List<Object> get props => [];
}

class ProductRemovedEvent extends InvoiceFormEvent {
  const ProductRemovedEvent(this.index);
  final int index;

  @override
  List<Object> get props => [index];
}

class ProductsClearedEvent extends InvoiceFormEvent {
  const ProductsClearedEvent();

  @override
  List<Object> get props => [];
}

class ProductSelectedEvent extends InvoiceFormEvent {
  const ProductSelectedEvent(this.product, this.index);
  final FormProduct product;
  final int index;

  @override
  List<Object> get props => [product];
}

class ProductUpdatedEvent extends InvoiceFormEvent {
  const ProductUpdatedEvent({this.reference, required this.product, required this.index});
  final Product? reference;
  final FormProduct product;
  final int index;

  @override
  List<Object?> get props => [reference, product, index];
}

class SaveInvoiceRequestEvent extends InvoiceFormEvent {
  const SaveInvoiceRequestEvent({
    required this.creatorId,
    required this.action,
    required this.creationDate,
  });
  final int creatorId;
  final DateTime creationDate;
  final InvoicePostAction action;

  @override
  List<Object> get props => [];
}

class DialogBoxClosedEvent extends InvoiceFormEvent {
  const DialogBoxClosedEvent();

  @override
  List<Object> get props => [];
}

class FormSubmittedEvent extends InvoiceFormEvent {
  const FormSubmittedEvent();

  @override
  List<Object> get props => [];
}
