import 'package:easthardware_pms/utils/undefined.dart';
import 'package:equatable/equatable.dart';

/// Data class for profit and loss entries
class ProfitLossEntry extends Equatable {
  const ProfitLossEntry({
    required this.date,
    required this.revenue,
    required this.expenses,
    required this.profit,
    required this.profitMargin,
  });

  final DateTime date;
  final double revenue;
  final double expenses;
  final double profit; // revenue - expenses
  final double profitMargin; // profit / revenue (as a percentage)

  ProfitLossEntry copyWith({
    DateTime? date,
    double? revenue,
    double? expenses,
    double? profit,
    double? profitMargin,
  }) {
    return ProfitLossEntry(
      date: date ?? this.date,
      revenue: revenue ?? this.revenue,
      expenses: expenses ?? this.expenses,
      profit: profit ?? this.profit,
      profitMargin: profitMargin ?? this.profitMargin,
    );
  }

  @override
  List<Object?> get props => [date, revenue, expenses, profit, profitMargin];
}

/// Data class for profit and loss summary
class ProfitLossSummary extends Equatable {
  const ProfitLossSummary({
    required this.totalRevenue,
    required this.totalExpenses,
    required this.totalProfit,
    required this.averageProfitMargin,
    required this.periodStart,
    required this.periodEnd,
  });

  final double totalRevenue;
  final double totalExpenses;
  final double totalProfit;
  final double averageProfitMargin;
  final DateTime periodStart;
  final DateTime periodEnd;

  ProfitLossSummary copyWith({
    double? totalRevenue,
    double? totalExpenses,
    double? totalProfit,
    double? averageProfitMargin,
    DateTime? periodStart,
    DateTime? periodEnd,
  }) {
    return ProfitLossSummary(
      totalRevenue: totalRevenue ?? this.totalRevenue,
      totalExpenses: totalExpenses ?? this.totalExpenses,
      totalProfit: totalProfit ?? this.totalProfit,
      averageProfitMargin: averageProfitMargin ?? this.averageProfitMargin,
      periodStart: periodStart ?? this.periodStart,
      periodEnd: periodEnd ?? this.periodEnd,
    );
  }

  @override
  List<Object?> get props => [
        totalRevenue,
        totalExpenses,
        totalProfit,
        averageProfitMargin,
        periodStart,
        periodEnd,
      ];
}

/// Enum for grouping the profit and loss report
enum ProfitLossGroupBy {
  day('Daily'),
  week('Weekly'),
  month('Monthly'),
  quarter('Quarterly'),
  year('Yearly');

  const ProfitLossGroupBy(this.name);
  final String name;
}

/// Sorting options for profit and loss report
enum ProfitLossSortBy {
  dateAscending('Date (Oldest First)'),
  dateDescending('Date (Newest First)'),
  revenueAscending('Revenue (Low to High)'),
  revenueDescending('Revenue (High to Low)'),
  expensesAscending('Expenses (Low to High)'),
  expensesDescending('Expenses (High to Low)'),
  profitAscending('Profit (Low to High)'),
  profitDescending('Profit (High to Low)'),
  profitMarginAscending('Profit Margin (Low to High)'),
  profitMarginDescending('Profit Margin (High to Low)');

  const ProfitLossSortBy(this.name);
  final String name;

  int compare(ProfitLossEntry a, ProfitLossEntry b) {
    switch (this) {
      case ProfitLossSortBy.dateAscending:
        return a.date.compareTo(b.date);
      case ProfitLossSortBy.dateDescending:
        return b.date.compareTo(a.date);
      case ProfitLossSortBy.revenueAscending:
        return a.revenue.compareTo(b.revenue);
      case ProfitLossSortBy.revenueDescending:
        return b.revenue.compareTo(a.revenue);
      case ProfitLossSortBy.expensesAscending:
        return a.expenses.compareTo(b.expenses);
      case ProfitLossSortBy.expensesDescending:
        return b.expenses.compareTo(a.expenses);
      case ProfitLossSortBy.profitAscending:
        return a.profit.compareTo(b.profit);
      case ProfitLossSortBy.profitDescending:
        return b.profit.compareTo(a.profit);
      case ProfitLossSortBy.profitMarginAscending:
        return a.profitMargin.compareTo(b.profitMargin);
      case ProfitLossSortBy.profitMarginDescending:
        return b.profitMargin.compareTo(a.profitMargin);
    }
  }
}

/// Query data for profit and loss report
class ProfitLossQueryData extends Equatable {
  factory ProfitLossQueryData.empty() {
    final now = DateTime.now();
    return ProfitLossQueryData(
      startDate: DateTime(now.year, now.month, 1),
      endDate: now,
    );
  }

  const ProfitLossQueryData({
    required this.startDate,
    required this.endDate,
    this.profitLossData,
    this.summary,
    this.groupBy = ProfitLossGroupBy.month,
    this.sortBy = ProfitLossSortBy.dateDescending,
  });

  final DateTime startDate;
  final DateTime endDate;
  final List<ProfitLossEntry>? profitLossData;
  final ProfitLossSummary? summary;
  final ProfitLossGroupBy groupBy;
  final ProfitLossSortBy sortBy;

  ProfitLossQueryData Function({
    DateTime? startDate,
    DateTime? endDate,
    List<ProfitLossEntry>? profitLossData,
    ProfitLossSummary? summary,
    ProfitLossGroupBy? groupBy,
    ProfitLossSortBy? sortBy,
  }) get copyWith {
    return ({
      Object? startDate = undefined,
      Object? endDate = undefined,
      Object? profitLossData = undefined,
      Object? summary = undefined,
      Object? groupBy = undefined,
      Object? sortBy = undefined,
    }) {
      return ProfitLossQueryData(
        startDate: startDate.or(this.startDate),
        endDate: endDate.or(this.endDate),
        profitLossData: profitLossData.or(this.profitLossData),
        summary: summary.or(this.summary),
        groupBy: groupBy.or(this.groupBy),
        sortBy: sortBy.or(this.sortBy),
      );
    };
  }

  @override
  List<Object?> get props => [startDate, endDate, profitLossData, summary, groupBy, sortBy];
}
