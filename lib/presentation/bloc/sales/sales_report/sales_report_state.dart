part of 'sales_report_bloc.dart';

class SalesReportState extends Equatable {
  const SalesReportState({
    required this.allProducts,
    required this.allInvoices,
    required this.allInvoiceProducts,
    required this.allOrders,
    required this.allOrderProducts,
    required this.queryData,
    this.isGenerating = false,
    this.overlayEntry,
  });

  final WeakReference<List<Product>> allProducts;
  final WeakReference<List<Invoice>> allInvoices;
  final WeakReference<List<InvoiceProduct>> allInvoiceProducts;
  final WeakReference<List<Order>> allOrders;
  final WeakReference<List<OrderProduct>> allOrderProducts;
  final SalesQueryData queryData;
  final bool isGenerating;
  final OverlayEntry? overlayEntry;

  SalesReportState Function({
    List<Product> allProducts,
    List<Invoice> allInvoices,
    List<InvoiceProduct> allInvoiceProducts,
    List<Order> allOrders,
    List<OrderProduct> allOrderProducts,
    SalesQueryData? queryData,
    bool? isGenerating,
    OverlayEntry? overlayEntry,
  }) get copyWith {
    return ({
      Object? allProducts = undefined,
      Object? allInvoices = undefined,
      Object? allInvoiceProducts = undefined,
      Object? allOrders = undefined,
      Object? allOrderProducts = undefined,
      Object? queryData = undefined,
      Object? isGenerating = undefined,
      Object? overlayEntry = undefined,
    }) {
      return SalesReportState(
        allProducts: allProducts.orWeakReference(this.allProducts),
        allInvoices: allInvoices.orWeakReference(this.allInvoices),
        allInvoiceProducts: allInvoiceProducts.orWeakReference(this.allInvoiceProducts),
        allOrders: allOrders.orWeakReference(this.allOrders),
        allOrderProducts: allOrderProducts.orWeakReference(this.allOrderProducts),
        queryData: queryData.or(this.queryData),
        isGenerating: isGenerating.or(this.isGenerating),
        overlayEntry: overlayEntry.or(this.overlayEntry),
      );
    };
  }

  @override
  List<Object?> get props => [
        allProducts,
        allInvoices,
        allInvoiceProducts,
        allOrders,
        allOrderProducts,
        queryData,
        isGenerating,
        overlayEntry,
      ];
}
