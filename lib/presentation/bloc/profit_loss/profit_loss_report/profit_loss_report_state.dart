part of 'profit_loss_report_bloc.dart';

class ProfitLossReportState extends Equatable {
  const ProfitLossReportState({
    required this.products,
    required this.invoices,
    required this.invoiceProducts,
    required this.orders,
    required this.orderProducts,
    required this.queryData,
    this.isGenerating = false,
    this.overlayEntry,
  });

  final List<Product> products;
  final List<Invoice> invoices;
  final List<InvoiceProduct> invoiceProducts;
  final List<Order> orders;
  final List<OrderProduct> orderProducts;
  final ProfitLossQueryData queryData;
  final bool isGenerating;
  final OverlayEntry? overlayEntry;

  ProfitLossReportState copyWith({
    List<Product>? products,
    List<Invoice>? invoices,
    List<InvoiceProduct>? invoiceProducts,
    List<Order>? orders,
    List<OrderProduct>? orderProducts,
    ProfitLossQueryData? queryData,
    bool? isGenerating,
    OverlayEntry? overlayEntry,
  }) {
    return ProfitLossReportState(
      products: products ?? this.products,
      invoices: invoices ?? this.invoices,
      invoiceProducts: invoiceProducts ?? this.invoiceProducts,
      orders: orders ?? this.orders,
      orderProducts: orderProducts ?? this.orderProducts,
      queryData: queryData ?? this.queryData,
      isGenerating: isGenerating ?? this.isGenerating,
      overlayEntry: overlayEntry ?? this.overlayEntry,
    );
  }

  @override
  List<Object?> get props => [
        products,
        invoices,
        invoiceProducts,
        orders,
        orderProducts,
        queryData,
        isGenerating,
      ];
}
