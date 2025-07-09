import 'package:easthardware_pms/domain/models/invoice.dart';
import 'package:easthardware_pms/domain/models/payment.dart';
import 'package:easthardware_pms/presentation/views/reports/common/reports_globals.dart';
import 'package:easthardware_pms/utils/compare_lowercase.dart';
import 'package:easthardware_pms/utils/undefined.dart';
import 'package:equatable/equatable.dart';

/// Extension to make working with the (Invoice, List<Payment>) tuple easier
extension InvoiceSalesDataPair on (Invoice, List<Payment>) {
  Invoice get invoice => $1;
  List<Payment> get payments => $2;

  String get customerName => invoice.customerName;
  int get invoiceId => invoice.id ?? 0;
  DateTime get invoiceDate => invoice.invoiceDate;
  DateTime get dueDate => invoice.dueDate;
  double get amountDue => invoice.amountDue;

  // Use invoice's amountPaid field if available, otherwise calculate from payments
  double get totalPaid =>
      invoice.amountPaid ?? payments.fold(0.0, (sum, payment) => sum + payment.amount);

  double get balanceDue => amountDue - totalPaid;
  double get overpayment => totalPaid > amountDue ? totalPaid - amountDue : 0.0;
  bool get isPaid => totalPaid >= amountDue;
  bool get isPartial => totalPaid > 0 && totalPaid < amountDue;
  bool get isUnpaid => totalPaid == 0;

  String get status {
    if (isPaid) return 'Paid';
    if (isPartial) return 'Partial';
    return 'Unpaid';
  }
}

/// Contains invoice sales data for a specific time period
class InvoiceSalesExtras extends Equatable {
  const InvoiceSalesExtras({
    required this.totalInvoices,
    required this.totalAmountDue,
    required this.totalAmountPaid,
    required this.totalBalanceDue,
    required this.totalOverpayment,
    required this.paidCount,
    required this.partialCount,
    required this.unpaidCount,
    required this.overpaidCount,
  });

  final int totalInvoices;
  final double totalAmountDue;
  final double totalAmountPaid;
  final double totalBalanceDue;
  final double totalOverpayment;
  final int paidCount;
  final int partialCount;
  final int unpaidCount;
  final int overpaidCount;

  InvoiceSalesExtras copyWith({
    int? totalInvoices,
    double? totalAmountDue,
    double? totalAmountPaid,
    double? totalBalanceDue,
    double? totalOverpayment,
    int? paidCount,
    int? partialCount,
    int? unpaidCount,
    int? overpaidCount,
  }) {
    return InvoiceSalesExtras(
      totalInvoices: totalInvoices ?? this.totalInvoices,
      totalAmountDue: totalAmountDue ?? this.totalAmountDue,
      totalAmountPaid: totalAmountPaid ?? this.totalAmountPaid,
      totalBalanceDue: totalBalanceDue ?? this.totalBalanceDue,
      totalOverpayment: totalOverpayment ?? this.totalOverpayment,
      paidCount: paidCount ?? this.paidCount,
      partialCount: partialCount ?? this.partialCount,
      unpaidCount: unpaidCount ?? this.unpaidCount,
      overpaidCount: overpaidCount ?? this.overpaidCount,
    );
  }

  @override
  List<Object?> get props => [
        totalInvoices,
        totalAmountDue,
        totalAmountPaid,
        totalBalanceDue,
        totalOverpayment,
        paidCount,
        partialCount,
        unpaidCount,
        overpaidCount,
      ];
}

/// Status filter for invoice sales report
enum InvoiceStatusFilter {
  all('All'),
  paid('Paid'),
  partial('Partial'),
  unpaid('Unpaid'),
  overpaid('Overpaid'),
  overdue('Overdue');

  const InvoiceStatusFilter(this.name);
  final String name;

  bool filterInvoice((Invoice, List<Payment>) invoiceData) {
    switch (this) {
      case InvoiceStatusFilter.all:
        return true;
      case InvoiceStatusFilter.paid:
        return invoiceData.isPaid && !invoiceData.overpayment.isNaN && invoiceData.overpayment <= 0;
      case InvoiceStatusFilter.partial:
        return invoiceData.isPartial;
      case InvoiceStatusFilter.unpaid:
        return invoiceData.isUnpaid;
      case InvoiceStatusFilter.overpaid:
        return invoiceData.overpayment > 0;
      case InvoiceStatusFilter.overdue:
        return !invoiceData.isPaid && invoiceData.dueDate.isBefore(DateTime.now());
    }
  }
}

/// Sorting options for the invoice sales report
enum InvoiceSalesReportSortBy {
  invoiceNumberAscending("Invoice # (Low to High)"),
  invoiceNumberDescending("Invoice # (High to Low)"),
  customerNameAscending("Customer (A-Z)"),
  customerNameDescending("Customer (Z-A)"),
  invoiceDateAscending("Invoice Date (Oldest First)"),
  invoiceDateDescending("Invoice Date (Newest First)"),
  dueDateAscending("Due Date (Oldest First)"),
  dueDateDescending("Due Date (Newest First)"),
  amountDueAscending("Amount Due (Low to High)"),
  amountDueDescending("Amount Due (High to Low)"),
  amountPaidAscending("Amount Paid (Low to High)"),
  amountPaidDescending("Amount Paid (High to Low)"),
  balanceDueAscending("Balance Due (Low to High)"),
  balanceDueDescending("Balance Due (High to Low)"),
  statusAscending("Status (Paid First)"),
  statusDescending("Status (Unpaid First)"),
  ;

  const InvoiceSalesReportSortBy(this.name);
  final String name;

  int compare((Invoice, List<Payment>) a, (Invoice, List<Payment>) b) {
    switch (this) {
      case InvoiceSalesReportSortBy.invoiceNumberAscending:
        return (a.invoice.id ?? 0).compareTo(b.invoice.id ?? 0);
      case InvoiceSalesReportSortBy.invoiceNumberDescending:
        return (b.invoice.id ?? 0).compareTo(a.invoice.id ?? 0);
      case InvoiceSalesReportSortBy.customerNameAscending:
        return a.invoice.customerName.compareToLowercase(b.invoice.customerName);
      case InvoiceSalesReportSortBy.customerNameDescending:
        return b.invoice.customerName.compareToLowercase(a.invoice.customerName);
      case InvoiceSalesReportSortBy.invoiceDateAscending:
        return a.invoice.invoiceDate.compareTo(b.invoice.invoiceDate);
      case InvoiceSalesReportSortBy.invoiceDateDescending:
        return b.invoice.invoiceDate.compareTo(a.invoice.invoiceDate);
      case InvoiceSalesReportSortBy.dueDateAscending:
        return a.invoice.dueDate.compareTo(b.invoice.dueDate);
      case InvoiceSalesReportSortBy.dueDateDescending:
        return b.invoice.dueDate.compareTo(a.invoice.dueDate);
      case InvoiceSalesReportSortBy.amountDueAscending:
        return a.invoice.amountDue.compareTo(b.invoice.amountDue);
      case InvoiceSalesReportSortBy.amountDueDescending:
        return b.invoice.amountDue.compareTo(a.invoice.amountDue);
      case InvoiceSalesReportSortBy.amountPaidAscending:
        return a.totalPaid.compareTo(b.totalPaid);
      case InvoiceSalesReportSortBy.amountPaidDescending:
        return b.totalPaid.compareTo(a.totalPaid);
      case InvoiceSalesReportSortBy.balanceDueAscending:
        return a.balanceDue.compareTo(b.balanceDue);
      case InvoiceSalesReportSortBy.balanceDueDescending:
        return b.balanceDue.compareTo(a.balanceDue);
      case InvoiceSalesReportSortBy.statusAscending:
        return a.status.compareTo(b.status);
      case InvoiceSalesReportSortBy.statusDescending:
        return b.status.compareTo(a.status);
    }
  }
}

/// Query data for the invoice sales report
class InvoiceSalesQueryData extends Equatable {
  factory InvoiceSalesQueryData.empty() {
    return InvoiceSalesQueryData(
      startDate: ReportsGlobals.defaultStartDate,
      endDate: ReportsGlobals.defaultEndDate,
    );
  }

  const InvoiceSalesQueryData({
    required this.startDate,
    required this.endDate,
    this.invoiceSalesData,
    this.invoiceSalesSummary,
    this.sortBy = InvoiceSalesReportSortBy.invoiceDateDescending,
    this.rowLimit,
    this.searchQuery = '',
    this.statusFilter = InvoiceStatusFilter.all,
    this.selectedCustomer,
  });

  final DateTime startDate;
  final DateTime endDate;
  final List<(Invoice, List<Payment>)>? invoiceSalesData;
  final InvoiceSalesExtras? invoiceSalesSummary;
  final InvoiceSalesReportSortBy sortBy;
  final int? rowLimit;
  final String searchQuery;
  final InvoiceStatusFilter statusFilter;
  final String? selectedCustomer;

  InvoiceSalesQueryData Function({
    DateTime startDate,
    DateTime endDate,
    List<(Invoice, List<Payment>)>? invoiceSalesData,
    InvoiceSalesExtras? invoiceSalesSummary,
    InvoiceSalesReportSortBy sortBy,
    int? rowLimit,
    String searchQuery,
    InvoiceStatusFilter statusFilter,
    String? selectedCustomer,
  }) get copyWith {
    return ({
      Object? startDate = undefined,
      Object? endDate = undefined,
      Object? invoiceSalesData = undefined,
      Object? invoiceSalesSummary = undefined,
      Object? sortBy = undefined,
      Object? rowLimit = undefined,
      Object? searchQuery = undefined,
      Object? statusFilter = undefined,
      Object? selectedCustomer = undefined,
    }) {
      return InvoiceSalesQueryData(
        startDate: startDate.or(this.startDate),
        endDate: endDate.or(this.endDate),
        invoiceSalesData: invoiceSalesData.or(this.invoiceSalesData),
        invoiceSalesSummary: invoiceSalesSummary.or(this.invoiceSalesSummary),
        sortBy: sortBy.or(this.sortBy),
        rowLimit: rowLimit.or(this.rowLimit),
        searchQuery: searchQuery.or(this.searchQuery),
        statusFilter: statusFilter.or(this.statusFilter),
        selectedCustomer: selectedCustomer.or(this.selectedCustomer),
      );
    };
  }

  @override
  List<Object?> get props => [
        startDate,
        endDate,
        invoiceSalesData,
        invoiceSalesSummary,
        sortBy,
        rowLimit,
        searchQuery,
        statusFilter,
        selectedCustomer,
      ];

  List<(Invoice, List<Payment>)>? get invoiceSalesDataWithRowLimit {
    if (rowLimit != null && invoiceSalesData != null) {
      return invoiceSalesData?.take(rowLimit!).toList();
    }
    return invoiceSalesData;
  }

  /// Filter and sort a list of invoice data pairs based on the current query parameters
  List<(Invoice, List<Payment>)> call(
    List<Invoice> invoices,
    List<Payment> payments,
  ) {
    // Filter invoices by date range
    final filteredInvoices = invoices.where((invoice) {
      return invoice.invoiceDate.isAfter(startDate.subtract(const Duration(days: 1))) &&
          invoice.invoiceDate.isBefore(endDate.add(const Duration(days: 1)));
    }).toList();

    // Map invoices to their payments
    final invoiceSalesData = <(Invoice, List<Payment>)>[];
    for (final invoice in filteredInvoices) {
      final invoicePayments = payments.where((payment) => payment.invoiceId == invoice.id).toList();
      invoiceSalesData.add((invoice, invoicePayments));
    }

    // Apply status filter
    var result = invoiceSalesData.where((data) => statusFilter.filterInvoice(data)).toList();

    // Apply customer filter if selected
    if (selectedCustomer != null && selectedCustomer!.isNotEmpty) {
      result = result
          .where((data) =>
              data.invoice.customerName.toLowerCase().contains(selectedCustomer!.toLowerCase()))
          .toList();
    }

    // Apply search query filter
    if (searchQuery.isNotEmpty) {
      result = result
          .where((data) =>
              data.invoice.customerName.toLowerCase().contains(searchQuery.toLowerCase()) ||
              (data.invoice.id?.toString() ?? '').contains(searchQuery))
          .toList();
    }

    // Apply sorting
    result.sort(sortBy.compare);

    return result;
  }
}
