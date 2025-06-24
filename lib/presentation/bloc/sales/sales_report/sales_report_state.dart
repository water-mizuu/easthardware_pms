part of 'sales_report_bloc.dart';

class SalesReportState extends Equatable {
  const SalesReportState({
    required this.allProducts,
    required this.allInvoices,
    required this.allInvoiceProducts,
    required this.allOrders,
    required this.allOrderProducts,
    required this.allCategories,
    required this.queryData,
    this.isGenerating = false,
    this.overlayEntry,
  });

  final List<Product> allProducts;
  final List<Invoice> allInvoices;
  final List<InvoiceProduct> allInvoiceProducts;
  final List<Order> allOrders;
  final List<OrderProduct> allOrderProducts;
  final List<Category> allCategories;
  final SalesQueryData queryData;
  final bool isGenerating;
  final OverlayEntry? overlayEntry;

  SalesReportState Function({
    List<Product> allProducts,
    List<Invoice> allInvoices,
    List<InvoiceProduct> allInvoiceProducts,
    List<Order> allOrders,
    List<OrderProduct> allOrderProducts,
    List<Category> allCategories,
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
      Object? allCategories = undefined,
      Object? queryData = undefined,
      Object? isGenerating = undefined,
      Object? overlayEntry = undefined,
    }) {
      return SalesReportState(
        allProducts: allProducts.or(this.allProducts),
        allInvoices: allInvoices.or(this.allInvoices),
        allInvoiceProducts: allInvoiceProducts.or(this.allInvoiceProducts),
        allOrders: allOrders.or(this.allOrders),
        allOrderProducts: allOrderProducts.or(this.allOrderProducts),
        allCategories: allCategories.or(this.allCategories),
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
