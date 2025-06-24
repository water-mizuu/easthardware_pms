part of 'business_snapshot_report_bloc.dart';

class BusinessSnapshotReportState extends Equatable {
  const BusinessSnapshotReportState({
    required this.products,
    required this.invoices,
    required this.invoiceProducts,
    required this.orders,
    required this.orderProducts,
    required this.expenseTypes,
    required this.queryData,
    this.isGenerating = false,
    this.overlayEntry,
    this.overlayKey,
    this.chartImage,
  });

  final List<Product> products;
  final List<Invoice> invoices;
  final List<InvoiceProduct> invoiceProducts;
  final List<Order> orders;
  final List<OrderProduct> orderProducts;
  final List<ExpenseType> expenseTypes;
  final BusinessSnapshotQueryData queryData;
  final bool isGenerating;
  final OverlayEntry? overlayEntry;
  final GlobalKey? overlayKey;
  final Uint8List? chartImage;

  BusinessSnapshotReportState Function({
    List<Product> products,
    List<Invoice> invoices,
    List<InvoiceProduct> invoiceProducts,
    List<Order> orders,
    List<OrderProduct> orderProducts,
    List<ExpenseType> expenseTypes,
    BusinessSnapshotQueryData queryData,
    bool isGenerating,
    OverlayEntry? overlayEntry,
    GlobalKey? overlayKey,
    Uint8List? chartImage,
  }) get copyWith {
    return ({
      Object? products = undefined,
      Object? invoices = undefined,
      Object? invoiceProducts = undefined,
      Object? orders = undefined,
      Object? orderProducts = undefined,
      Object? expenseTypes = undefined,
      Object? queryData = undefined,
      Object? isGenerating = undefined,
      Object? overlayEntry = undefined,
      Object? overlayKey = undefined,
      Object? chartImage = undefined,
    }) {
      return BusinessSnapshotReportState(
        products: products.or(this.products),
        invoices: invoices.or(this.invoices),
        invoiceProducts: invoiceProducts.or(this.invoiceProducts),
        orders: orders.or(this.orders),
        orderProducts: orderProducts.or(this.orderProducts),
        expenseTypes: expenseTypes.or(this.expenseTypes),
        queryData: queryData.or(this.queryData),
        isGenerating: isGenerating.or(this.isGenerating),
        overlayEntry: overlayEntry.or(this.overlayEntry),
        overlayKey: overlayKey.or(this.overlayKey),
        chartImage: chartImage.or(this.chartImage),
      );
    };
  }

  @override
  List<Object?> get props => [
        products,
        invoices,
        invoiceProducts,
        orders,
        orderProducts,
        expenseTypes,
        queryData,
        isGenerating,
        overlayEntry,
        overlayKey,
        chartImage,
      ];
}
