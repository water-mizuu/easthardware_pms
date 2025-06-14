part of 'invoice_list_bloc.dart';

sealed class InvoiceListEvent extends Equatable {
  const InvoiceListEvent();

  @override
  List<Object> get props => [];
}

class FetchAllInvoicesEvent extends InvoiceListEvent {
  const FetchAllInvoicesEvent();

  @override
  List<Object> get props => [];
}

class AddInvoiceEvent extends InvoiceListEvent {
  const AddInvoiceEvent(this.invoice);

  final Invoice invoice;

  @override
  List<Object> get props => [invoice];
}

class UpdateInvoiceEvent extends InvoiceListEvent {
  const UpdateInvoiceEvent(this.invoice);

  final Invoice invoice;

  @override
  List<Object> get props => [invoice];
}

class DeleteInvoiceEvent extends InvoiceListEvent {
  const DeleteInvoiceEvent(this.invoice);

  final Invoice invoice;

  @override
  List<Object> get props => [invoice];
}

class FetchInvoiceProductsEvent extends InvoiceListEvent {
  const FetchInvoiceProductsEvent(this.invoiceId);

  final int invoiceId;

  @override
  List<Object> get props => [invoiceId];
}

class AddInvoiceProductEvent extends InvoiceListEvent {
  const AddInvoiceProductEvent(this.invoiceId, this.product);

  final int invoiceId;
  final InvoiceProduct product;

  @override
  List<Object> get props => [invoiceId, product];
}

class UpdateInvoiceProductEvent extends InvoiceListEvent {
  const UpdateInvoiceProductEvent(this.invoiceId, this.product);

  final int invoiceId;
  final InvoiceProduct product;

  @override
  List<Object> get props => [invoiceId, product];
}

class DeleteInvoiceProductEvent extends InvoiceListEvent {
  const DeleteInvoiceProductEvent(this.invoiceId, this.productId);

  final int invoiceId;
  final int productId;

  @override
  List<Object> get props => [invoiceId, productId];
}
