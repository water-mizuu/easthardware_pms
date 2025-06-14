part of 'invoice_list_bloc.dart';

class InvoiceListState extends Equatable {
  const InvoiceListState({
    this.invoices = const [],
    this.status = DataStatus.initial,
    this.invoiceProducts,
  });

  final List<Invoice> invoices;
  final DataStatus status;
  final List<InvoiceProduct>? invoiceProducts;

  InvoiceListState copyWith({
    List<Invoice>? invoices,
    DataStatus? status,
    List<InvoiceProduct>? invoiceProducts,
  }) {
    return InvoiceListState(
      invoices: invoices ?? this.invoices,
      status: status ?? this.status,
      invoiceProducts: this.invoiceProducts,
    );
  }

  @override
  List<Object> get props => [
        invoices,
        status,
      ];
}
