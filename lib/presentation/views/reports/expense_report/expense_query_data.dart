import 'package:easthardware_pms/domain/models/expense_type.dart';
import 'package:easthardware_pms/domain/models/order.dart';
import 'package:easthardware_pms/presentation/views/reports/common/reports_globals.dart';
import 'package:easthardware_pms/utils/compare_lowercase.dart';
import 'package:easthardware_pms/utils/undefined.dart';
import 'package:equatable/equatable.dart';

/// Extension to make working with the (Order, ExpenseType) tuple easier
extension ExpenseDataPair on (Order, ExpenseType) {
  Order get order => $1;
  ExpenseType get expenseType => $2;

  String get payeeName => order.payeeName;
  String get expenseTypeName => expenseType.name;
  DateTime get orderDate => order.orderDate;
  double get amountDue => order.amountDue;
  double get amountPaid => order.amountPaid ?? 0.0;
  double get remaining => amountDue - amountPaid;
  bool get isPaid => amountPaid >= amountDue;
}

/// Contains expense data for a specific expense type
class ExpenseExtras extends Equatable {
  const ExpenseExtras({
    required this.expenseType,
    required this.totalAmount,
    required this.orderCount,
  });

  final ExpenseType expenseType;
  final double totalAmount;
  final int orderCount;

  ExpenseExtras copyWith({
    ExpenseType? expenseType,
    double? totalAmount,
    int? orderCount,
  }) {
    return ExpenseExtras(
      expenseType: expenseType ?? this.expenseType,
      totalAmount: totalAmount ?? this.totalAmount,
      orderCount: orderCount ?? this.orderCount,
    );
  }

  @override
  List<Object?> get props => [expenseType, totalAmount, orderCount];
}

/// Payment status filter for expense report
enum ExpensePaymentStatusFilter {
  all('All'),
  paid('Paid'),
  unpaid('Unpaid');

  const ExpensePaymentStatusFilter(this.name);
  final String name;

  bool filterExpense((Order, ExpenseType) expenseData) {
    switch (this) {
      case ExpensePaymentStatusFilter.all:
        return true;
      case ExpensePaymentStatusFilter.paid:
        return expenseData.isPaid;
      case ExpensePaymentStatusFilter.unpaid:
        return !expenseData.isPaid;
    }
  }
}

/// Sorting options for the expense report
enum ExpenseReportSortBy {
  expenseTypeAscending("Expense Type (A-Z)"),
  expenseTypeDescending("Expense Type (Z-A)"),
  payeeNameAscending("Payee (A-Z)"),
  payeeNameDescending("Payee (Z-A)"),
  amountDueAscending("Amount Due (Low to High)"),
  amountDueDescending("Amount Due (High to Low)"),
  amountPaidAscending("Amount Paid (Low to High)"),
  amountPaidDescending("Amount Paid (High to Low)"),
  remainingAscending("Remaining (Low to High)"),
  remainingDescending("Remaining (High to Low)"),
  dateAscending("Date (Oldest First)"),
  dateDescending("Date (Newest First)"),
  ;

  const ExpenseReportSortBy(this.name);
  final String name;

  int compare((Order, ExpenseType) a, (Order, ExpenseType) b) {
    switch (this) {
      case ExpenseReportSortBy.expenseTypeAscending:
        return a.expenseType.name.compareToLowercase(b.expenseType.name);
      case ExpenseReportSortBy.expenseTypeDescending:
        return b.expenseType.name.compareToLowercase(a.expenseType.name);
      case ExpenseReportSortBy.payeeNameAscending:
        return a.order.payeeName.compareToLowercase(b.order.payeeName);
      case ExpenseReportSortBy.payeeNameDescending:
        return b.order.payeeName.compareToLowercase(a.order.payeeName);
      case ExpenseReportSortBy.amountDueAscending:
        return a.order.amountDue.compareTo(b.order.amountDue);
      case ExpenseReportSortBy.amountDueDescending:
        return b.order.amountDue.compareTo(a.order.amountDue);
      case ExpenseReportSortBy.amountPaidAscending:
        return (a.order.amountPaid ?? 0.0).compareTo(b.order.amountPaid ?? 0.0);
      case ExpenseReportSortBy.amountPaidDescending:
        return (b.order.amountPaid ?? 0.0).compareTo(a.order.amountPaid ?? 0.0);
      case ExpenseReportSortBy.remainingAscending:
        return (a.order.amountDue - (a.order.amountPaid ?? 0.0))
            .compareTo(b.order.amountDue - (b.order.amountPaid ?? 0.0));
      case ExpenseReportSortBy.remainingDescending:
        return (b.order.amountDue - (b.order.amountPaid ?? 0.0))
            .compareTo(a.order.amountDue - (a.order.amountPaid ?? 0.0));
      case ExpenseReportSortBy.dateAscending:
        return a.order.orderDate.compareTo(b.order.orderDate);
      case ExpenseReportSortBy.dateDescending:
        return b.order.orderDate.compareTo(a.order.orderDate);
    }
  }
}

/// Query data for the expense report
class ExpenseQueryData extends Equatable {
  factory ExpenseQueryData.empty() {
    return ExpenseQueryData(
      startDate: ReportsGlobals.defaultStartDate,
      endDate: ReportsGlobals.defaultEndDate,
    );
  }
  const ExpenseQueryData({
    required this.startDate,
    required this.endDate,
    this.expenseData,
    this.expenseSummary,
    this.sortBy = ExpenseReportSortBy.dateDescending,
    this.rowLimit,
    this.searchQuery = '',
    this.paymentStatusFilter = ExpensePaymentStatusFilter.all,
    this.selectedExpenseType,
    this.selectedPayee,
  });

  final DateTime startDate;
  final DateTime endDate;
  final List<(Order, ExpenseType)>? expenseData;
  final List<ExpenseExtras>? expenseSummary;
  final ExpenseReportSortBy sortBy;
  final int? rowLimit;
  final String searchQuery;
  final ExpensePaymentStatusFilter paymentStatusFilter;
  final ExpenseType? selectedExpenseType;
  final String? selectedPayee;

  ExpenseQueryData Function({
    DateTime startDate,
    DateTime endDate,
    List<(Order, ExpenseType)>? expenseData,
    List<ExpenseExtras>? expenseSummary,
    ExpenseReportSortBy sortBy,
    int? rowLimit,
    String searchQuery,
    ExpensePaymentStatusFilter paymentStatusFilter,
    ExpenseType? selectedExpenseType,
    String? selectedPayee,
  }) get copyWith {
    return ({
      Object? startDate = undefined,
      Object? endDate = undefined,
      Object? expenseData = undefined,
      Object? expenseSummary = undefined,
      Object? sortBy = undefined,
      Object? rowLimit = undefined,
      Object? searchQuery = undefined,
      Object? paymentStatusFilter = undefined,
      Object? selectedExpenseType = undefined,
      Object? selectedPayee = undefined,
    }) {
      return ExpenseQueryData(
        startDate: startDate.or(this.startDate),
        endDate: endDate.or(this.endDate),
        expenseData: expenseData.or(this.expenseData),
        expenseSummary: expenseSummary.or(this.expenseSummary),
        sortBy: sortBy.or(this.sortBy),
        rowLimit: rowLimit.or(this.rowLimit),
        searchQuery: searchQuery.or(this.searchQuery),
        paymentStatusFilter: paymentStatusFilter.or(this.paymentStatusFilter),
        selectedExpenseType: selectedExpenseType.or(this.selectedExpenseType),
        selectedPayee: selectedPayee.or(this.selectedPayee),
      );
    };
  }

  @override
  List<Object?> get props => [
        startDate,
        endDate,
        expenseData,
        expenseSummary,
        sortBy,
        rowLimit,
        searchQuery,
        paymentStatusFilter,
        selectedExpenseType,
        selectedPayee,
      ];

  List<(Order, ExpenseType)>? get expenseDataWithRowLimit {
    if (rowLimit != null && expenseData != null) {
      return expenseData?.take(rowLimit!).toList();
    }
    return expenseData;
  }

  /// Filter and sort a list of expense data pairs based on the current query parameters
  List<(Order, ExpenseType)> call(
    List<Order> orders,
    List<ExpenseType> expenseTypes,
  ) {
    // Filter orders by date range
    final filteredOrders = orders.where((order) {
      return order.orderDate.isAfter(startDate) &&
          order.orderDate.isBefore(endDate.add(const Duration(days: 1)));
    }).toList();

    // Map orders to their expense types
    final expenseData = <(Order, ExpenseType)>[];
    for (final order in filteredOrders) {
      final expenseType = expenseTypes.firstWhere(
        (type) => type.id == order.expenseType,
        orElse: () => const ExpenseType(name: 'Unknown'),
      );
      expenseData.add((order, expenseType));
    }

    // Apply payment status filter
    var result = expenseData.where((data) => paymentStatusFilter.filterExpense(data)).toList();

    // Apply expense type filter if selected
    if (selectedExpenseType != null) {
      result = result.where((data) => data.expenseType.id == selectedExpenseType!.id).toList();
    }

    // Apply payee filter if selected
    if (selectedPayee != null && selectedPayee!.isNotEmpty) {
      result = result
          .where(
              (data) => data.order.payeeName.toLowerCase().contains(selectedPayee!.toLowerCase()))
          .toList();
    }

    // Apply search query filter
    if (searchQuery.isNotEmpty) {
      result = result
          .where((data) =>
              data.order.payeeName.toLowerCase().contains(searchQuery.toLowerCase()) ||
              data.expenseType.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
              (data.order.id?.toString() ?? '').contains(searchQuery))
          .toList();
    }

    // Apply sorting
    result.sort(sortBy.compare);

    return result;
  }
}
