part of 'invoice_form_bloc.dart';

sealed class InvoiceFormEvent extends Equatable {
  const InvoiceFormEvent();

  @override
  List<Object> get props => [];
}

class CustomerNameChangedEvent extends InvoiceFormEvent {
  final String customerName;

  const CustomerNameChangedEvent(this.customerName);

  @override
  List<Object> get props => [customerName];
}

class InvoiceDateChangedEvent extends InvoiceFormEvent {
  final DateTime invoiceDate;

  const InvoiceDateChangedEvent(this.invoiceDate);

  @override
  List<Object> get props => [invoiceDate];
}

class DueDateChangedEvent extends InvoiceFormEvent {
  final DateTime dueDate;

  const DueDateChangedEvent(this.dueDate);

  @override
  List<Object> get props => [dueDate];
}

class MemoChangedEvent extends InvoiceFormEvent {
  final String memo;

  const MemoChangedEvent(this.memo);

  @override
  List<Object> get props => [memo];
}

class DiscountChangedEvent extends InvoiceFormEvent {
  final double discount;

  const DiscountChangedEvent(this.discount);

  @override
  List<Object> get props => [discount];
}

class ProductAddedEvent extends InvoiceFormEvent {
  const ProductAddedEvent();

  @override
  List<Object> get props => [];
}

class ProductRemovedEvent extends InvoiceFormEvent {
  final int index;

  const ProductRemovedEvent(this.index);

  @override
  List<Object> get props => [index];
}

class ProductSelectedEvent extends InvoiceFormEvent {
  final Product product;
  final int index;

  const ProductSelectedEvent(this.product, this.index);

  @override
  List<Object> get props => [product];
}

class ProductUpdatedEvent extends InvoiceFormEvent {
  final FormProduct product;
  final int index;

  const ProductUpdatedEvent(this.product, this.index);

  @override
  List<Object> get props => [product];
}

class FormButtonPressedEvent extends InvoiceFormEvent {
  const FormButtonPressedEvent();

  @override
  List<Object> get props => [];
}

class FormSubmittedEvent extends InvoiceFormEvent {
  const FormSubmittedEvent();

  @override
  List<Object> get props => [];
}

class FormResetEvent extends InvoiceFormEvent {
  const FormResetEvent();

  @override
  List<Object> get props => [];
}
