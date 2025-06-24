part of 'inventory_report_bloc.dart';

class InventoryReportState extends Equatable {
  const InventoryReportState({
    required this.allInvoices,
    required this.allInvoiceProducts,
    required this.allOrders,
    required this.allOrderProducts,
    required this.allProducts,
    required this.queryData,
    this.isGenerating = false,
    this.overlayEntry,
  });

  final List<Invoice> allInvoices;
  final List<InvoiceProduct> allInvoiceProducts;

  final List<Order> allOrders;
  final List<OrderProduct> allOrderProducts;

  final List<Product> allProducts;
  final InventoryQueryData queryData;
  final bool isGenerating;
  final OverlayEntry? overlayEntry;

  InventoryReportState Function({
    List<Invoice> allInvoices,
    List<InvoiceProduct> allInvoiceProducts,
    List<Order> allOrders,
    List<OrderProduct> allOrderProducts,
    List<Product> allProducts,
    InventoryQueryData queryData,
    bool isGenerating,
    OverlayEntry? overlayEntry,
  }) get copyWith {
    return ({
      Object? allInvoiceProducts = undefined,
      Object? allInvoices = undefined,
      Object? allOrderProducts = undefined,
      Object? allOrders = undefined,
      Object? allProducts = undefined,
      Object? queryData = undefined,
      Object? isGenerating = undefined,
      Object? overlayEntry = undefined,
    }) {
      return InventoryReportState(
        allInvoices: allInvoices.or(this.allInvoices),
        allInvoiceProducts: allInvoiceProducts.or(this.allInvoiceProducts),
        allOrders: allOrders.or(this.allOrders),
        allOrderProducts: allOrderProducts.or(this.allOrderProducts),
        allProducts: allProducts.or(this.allProducts),
        queryData: queryData.or(this.queryData),
        isGenerating: isGenerating.or(this.isGenerating),
        overlayEntry: overlayEntry.or(this.overlayEntry),
      );
    };
  }

  @override
  List<Object?> get props => [
        allProducts,
        queryData,
        isGenerating,
        overlayEntry,
      ];
}
