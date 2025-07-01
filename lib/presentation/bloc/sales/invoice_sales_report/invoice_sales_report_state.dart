part of 'invoice_sales_report_bloc.dart';

class InvoiceSalesReportState extends Equatable {
  const InvoiceSalesReportState({
    required this.allInvoices,
    required this.allPayments,
    required this.queryData,
    this.isGenerating = false,
    this.overlayEntry,
  });

  final List<Invoice> allInvoices;
  final List<Payment> allPayments;
  final InvoiceSalesQueryData queryData;
  final bool isGenerating;
  final OverlayEntry? overlayEntry;

  InvoiceSalesReportState Function({
    List<Invoice> allInvoices,
    List<Payment> allPayments,
    InvoiceSalesQueryData queryData,
    bool isGenerating,
    OverlayEntry? overlayEntry,
  }) get copyWith {
    return ({
      Object? allInvoices = undefined,
      Object? allPayments = undefined,
      Object? queryData = undefined,
      Object? isGenerating = undefined,
      Object? overlayEntry = undefined,
    }) {
      return InvoiceSalesReportState(
        allInvoices: allInvoices.or(this.allInvoices),
        allPayments: allPayments.or(this.allPayments),
        queryData: queryData.or(this.queryData),
        isGenerating: isGenerating.or(this.isGenerating),
        overlayEntry: overlayEntry.or(this.overlayEntry),
      );
    };
  }

  @override
  List<Object?> get props => [
        allInvoices,
        allPayments,
        queryData,
        isGenerating,
        overlayEntry,
      ];
}
