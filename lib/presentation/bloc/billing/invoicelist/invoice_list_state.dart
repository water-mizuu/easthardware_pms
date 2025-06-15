part of 'invoice_list_bloc.dart';

class InvoiceListState extends Equatable {
  const InvoiceListState({
    this.invoices = const [],
    this.latest,
    this.status = DataStatus.initial,
    this.invoiceProducts = const [],
  });

  final List<Invoice> invoices;
  final Invoice? latest;
  final DataStatus status;
  final List<InvoiceProduct> invoiceProducts;

  InvoiceListState copyWith({
    List<Invoice>? invoices,
    Invoice? latest,
    DataStatus? status,
    List<InvoiceProduct>? invoiceProducts,
  }) {
    return InvoiceListState(
      latest: latest ?? this.latest,
      invoices: invoices ?? this.invoices,
      status: status ?? this.status,
      invoiceProducts: this.invoiceProducts,
    );
  }

  @override
  List<Object> get props => [
        invoices,
        status,
        invoiceProducts,
      ];
}
