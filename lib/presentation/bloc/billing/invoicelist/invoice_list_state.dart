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

  InvoiceListState Function({
    List<Invoice>? invoices,
    Invoice? latest,
    DataStatus? status,
    List<InvoiceProduct>? invoiceProducts,
  }) get copyWith {
    return ({
      Object? invoices = undefined,
      Object? latest = undefined,
      Object? status = undefined,
      Object? invoiceProducts = undefined,
    }) {
      return InvoiceListState(
        invoices: invoices.or(this.invoices),
        latest: latest.or(this.latest),
        status: status.or(this.status),
        invoiceProducts: invoiceProducts.or(this.invoiceProducts),
      );
    };
  }

  @override
  List<Object> get props => [
        invoices,
        status,
        invoiceProducts,
      ];
}
