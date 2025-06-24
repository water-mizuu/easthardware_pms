import 'package:easthardware_pms/domain/models/expense_type.dart';
import 'package:easthardware_pms/domain/models/order.dart';
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
  statusPaid("Status (Paid First)"),
  statusUnpaid("Status (Unpaid First)"),
  ;

  const ExpenseReportSortBy(this.name);
  final String name;

  int compare(
    (Order, ExpenseType) a,
    (Order, ExpenseType) b,
  ) {
    switch (this) {
      case ExpenseReportSortBy.expenseTypeAscending:
        return a.expenseType.name.compareTo(b.expenseType.name);
      case ExpenseReportSortBy.expenseTypeDescending:
        return b.expenseType.name.compareTo(a.expenseType.name);
      case ExpenseReportSortBy.payeeNameAscending:
        return a.order.payeeName.compareTo(b.order.payeeName);
      case ExpenseReportSortBy.payeeNameDescending:
        return b.order.payeeName.compareTo(a.order.payeeName);
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
      case ExpenseReportSortBy.statusPaid:
        // Paid first (true before false)
        final aPaid = (a.order.amountPaid ?? 0) >= a.order.amountDue;
        final bPaid = (b.order.amountPaid ?? 0) >= b.order.amountDue;
        return bPaid == aPaid ? 0 : (aPaid ? -1 : 1);
      case ExpenseReportSortBy.statusUnpaid:
        // Unpaid first (false before true)
        final aPaid = (a.order.amountPaid ?? 0) >= a.order.amountDue;
        final bPaid = (b.order.amountPaid ?? 0) >= b.order.amountDue;
        return bPaid == aPaid ? 0 : (aPaid ? 1 : -1);
    }
  }
}

/// Query data for the expense report
class ExpenseQueryData extends Equatable {
  factory ExpenseQueryData.empty() {
    final now = DateTime.now();
    return ExpenseQueryData(
      startDate: DateTime(now.year, now.month, 1),
      endDate: now,
    );
  }
  const ExpenseQueryData({
    required this.startDate,
    required this.endDate,
    this.expenseData,
    this.expenseSummary,
    this.sortBy = ExpenseReportSortBy.dateDescending,
  });

  final DateTime startDate;
  final DateTime endDate;
  final List<(Order, ExpenseType)>? expenseData;
  final List<ExpenseExtras>? expenseSummary;
  final ExpenseReportSortBy sortBy;

  ExpenseQueryData Function({
    DateTime? startDate,
    DateTime? endDate,
    List<(Order, ExpenseType)>? expenseData,
    List<ExpenseExtras>? expenseSummary,
    ExpenseReportSortBy? sortBy,
  }) get copyWith {
    return ({
      Object? startDate = undefined,
      Object? endDate = undefined,
      Object? expenseData = undefined,
      Object? expenseSummary = undefined,
      Object? sortBy = undefined,
    }) {
      return ExpenseQueryData(
        startDate: startDate.or(this.startDate),
        endDate: endDate.or(this.endDate),
        expenseData: expenseData.or(this.expenseData),
        expenseSummary: expenseSummary.or(this.expenseSummary),
        sortBy: sortBy.or(this.sortBy),
      );
    };
  }

  @override
  List<Object?> get props => [startDate, endDate, expenseData, expenseSummary, sortBy];
}
