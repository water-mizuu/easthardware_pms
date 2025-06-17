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
  const AddInvoiceEvent(this.invoice, this.invoiceProducts);

  final Invoice invoice;
  final List<InvoiceProduct> invoiceProducts;

  @override
  List<Object> get props => [invoice, invoiceProducts];
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
