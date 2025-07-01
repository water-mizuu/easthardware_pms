import 'package:easthardware_pms/domain/models/category.dart';
import 'package:easthardware_pms/domain/models/expense_type.dart';
import 'package:easthardware_pms/domain/models/product.dart';
import 'package:easthardware_pms/presentation/views/reports/common/reports_globals.dart';
import 'package:easthardware_pms/utils/undefined.dart';
import 'package:equatable/equatable.dart';

/// Data class for business snapshot metrics
class BusinessMetric extends Equatable {
  const BusinessMetric({
    required this.name,
    required this.currentValue,
    required this.previousValue,
    required this.percentageChange,
    this.isPositiveTrend = true,
  });

  final String name;
  final double currentValue;
  final double previousValue;
  final double percentageChange;
  final bool isPositiveTrend; // Whether an increase is positive (true) or negative (false)

  // Used for UI to determine if the change is positive or negative, considering the metric type
  bool get isPositiveChange =>
      (percentageChange >= 0 && isPositiveTrend) || (percentageChange < 0 && !isPositiveTrend);

  BusinessMetric copyWith({
    String? name,
    double? currentValue,
    double? previousValue,
    double? percentageChange,
    bool? isPositiveTrend,
  }) {
    return BusinessMetric(
      name: name ?? this.name,
      currentValue: currentValue ?? this.currentValue,
      previousValue: previousValue ?? this.previousValue,
      percentageChange: percentageChange ?? this.percentageChange,
      isPositiveTrend: isPositiveTrend ?? this.isPositiveTrend,
    );
  }

  @override
  List<Object?> get props => [
        name,
        currentValue,
        previousValue,
        percentageChange,
        isPositiveTrend,
      ];
}

/// Data class for top selling products in the business snapshot
class TopSellingProduct extends Equatable {
  const TopSellingProduct({
    required this.product,
    required this.quantitySold,
    required this.revenue,
    required this.profit,
  });

  final Product product;
  final double quantitySold;
  final double revenue;
  final double profit;

  TopSellingProduct copyWith({
    Product? product,
    double? quantitySold,
    double? revenue,
    double? profit,
  }) {
    return TopSellingProduct(
      product: product ?? this.product,
      quantitySold: quantitySold ?? this.quantitySold,
      revenue: revenue ?? this.revenue,
      profit: profit ?? this.profit,
    );
  }

  @override
  List<Object?> get props => [
        product,
        quantitySold,
        revenue,
        profit,
      ];
}

/// Data class for expense breakdown in the business snapshot
class ExpenseBreakdown extends Equatable {
  const ExpenseBreakdown({
    required this.expenseType,
    required this.amount,
    required this.percentage,
  });

  final ExpenseType expenseType;
  final double amount;
  final double percentage; // Percentage of total expenses

  ExpenseBreakdown copyWith({
    ExpenseType? expenseType,
    double? amount,
    double? percentage,
  }) {
    return ExpenseBreakdown(
      expenseType: expenseType ?? this.expenseType,
      amount: amount ?? this.amount,
      percentage: percentage ?? this.percentage,
    );
  }

  @override
  List<Object?> get props => [
        expenseType,
        amount,
        percentage,
      ];
}

/// Chart data for revenue trends
class RevenueTrend extends Equatable {
  const RevenueTrend({
    required this.date,
    required this.revenue,
    required this.expenses,
    required this.profit,
  });

  final DateTime date;
  final double revenue;
  final double expenses;
  final double profit;

  RevenueTrend copyWith({
    DateTime? date,
    double? revenue,
    double? expenses,
    double? profit,
  }) {
    return RevenueTrend(
      date: date ?? this.date,
      revenue: revenue ?? this.revenue,
      expenses: expenses ?? this.expenses,
      profit: profit ?? this.profit,
    );
  }

  @override
  List<Object?> get props => [
        date,
        revenue,
        expenses,
        profit,
      ];
}

/// Data class for business summary
class BusinessSummary extends Equatable {
  const BusinessSummary({
    required this.totalRevenue,
    required this.totalExpenses,
    required this.totalProfit,
    required this.profitMargin,
    required this.totalProducts,
    required this.lowStockProducts,
    required this.totalOrders,
    required this.pendingOrders,
  });

  final double totalRevenue;
  final double totalExpenses;
  final double totalProfit;
  final double profitMargin;
  final int totalProducts;
  final int lowStockProducts;
  final int totalOrders;
  final int pendingOrders;

  BusinessSummary copyWith({
    double? totalRevenue,
    double? totalExpenses,
    double? totalProfit,
    double? profitMargin,
    int? totalProducts,
    int? lowStockProducts,
    int? totalOrders,
    int? pendingOrders,
  }) {
    return BusinessSummary(
      totalRevenue: totalRevenue ?? this.totalRevenue,
      totalExpenses: totalExpenses ?? this.totalExpenses,
      totalProfit: totalProfit ?? this.totalProfit,
      profitMargin: profitMargin ?? this.profitMargin,
      totalProducts: totalProducts ?? this.totalProducts,
      lowStockProducts: lowStockProducts ?? this.lowStockProducts,
      totalOrders: totalOrders ?? this.totalOrders,
      pendingOrders: pendingOrders ?? this.pendingOrders,
    );
  }

  @override
  List<Object?> get props => [
        totalRevenue,
        totalExpenses,
        totalProfit,
        profitMargin,
        totalProducts,
        lowStockProducts,
        totalOrders,
        pendingOrders,
      ];
}

/// Enum for period comparison in business snapshot
enum BusinessSnapshotPeriod {
  day('Day'),
  week('Week'),
  month('Month'),
  quarter('Quarter'),
  year('Year');

  const BusinessSnapshotPeriod(this.name);
  final String name;
}

/// Sorting options for top selling products
enum TopSellingProductSortBy {
  nameAscending('Name (A-Z)'),
  nameDescending('Name (Z-A)'),
  quantitySoldAscending('Quantity Sold (Low to High)'),
  quantitySoldDescending('Quantity Sold (High to Low)'),
  revenueAscending('Revenue (Low to High)'),
  revenueDescending('Revenue (High to Low)'),
  profitAscending('Profit (Low to High)'),
  profitDescending('Profit (High to Low)');

  const TopSellingProductSortBy(this.name);
  final String name;

  int compare(TopSellingProduct a, TopSellingProduct b) {
    switch (this) {
      case TopSellingProductSortBy.nameAscending:
        return a.product.name.compareTo(b.product.name);
      case TopSellingProductSortBy.nameDescending:
        return b.product.name.compareTo(a.product.name);
      case TopSellingProductSortBy.quantitySoldAscending:
        return a.quantitySold.compareTo(b.quantitySold);
      case TopSellingProductSortBy.quantitySoldDescending:
        return b.quantitySold.compareTo(a.quantitySold);
      case TopSellingProductSortBy.revenueAscending:
        return a.revenue.compareTo(b.revenue);
      case TopSellingProductSortBy.revenueDescending:
        return b.revenue.compareTo(a.revenue);
      case TopSellingProductSortBy.profitAscending:
        return a.profit.compareTo(b.profit);
      case TopSellingProductSortBy.profitDescending:
        return b.profit.compareTo(a.profit);
    }
  }
}

/// Sorting options for expense breakdown
enum ExpenseBreakdownSortBy {
  nameAscending('Name (A-Z)'),
  nameDescending('Name (Z-A)'),
  amountAscending('Amount (Low to High)'),
  amountDescending('Amount (High to Low)'),
  percentageAscending('Percentage (Low to High)'),
  percentageDescending('Percentage (High to Low)');

  const ExpenseBreakdownSortBy(this.name);
  final String name;

  int compare(ExpenseBreakdown a, ExpenseBreakdown b) {
    switch (this) {
      case ExpenseBreakdownSortBy.nameAscending:
        return a.expenseType.name.compareTo(b.expenseType.name);
      case ExpenseBreakdownSortBy.nameDescending:
        return b.expenseType.name.compareTo(a.expenseType.name);
      case ExpenseBreakdownSortBy.amountAscending:
        return a.amount.compareTo(b.amount);
      case ExpenseBreakdownSortBy.amountDescending:
        return b.amount.compareTo(a.amount);
      case ExpenseBreakdownSortBy.percentageAscending:
        return a.percentage.compareTo(b.percentage);
      case ExpenseBreakdownSortBy.percentageDescending:
        return b.percentage.compareTo(a.percentage);
    }
  }
}

/// Sorting options for key metrics
enum BusinessMetricSortBy {
  nameAscending('Metric (A-Z)'),
  nameDescending('Metric (Z-A)'),
  currentValueAscending('Current Value (Low to High)'),
  currentValueDescending('Current Value (High to Low)'),
  previousValueAscending('Previous Value (Low to High)'),
  previousValueDescending('Previous Value (High to Low)'),
  percentageChangeAscending('Change % (Low to High)'),
  percentageChangeDescending('Change % (High to Low)');

  const BusinessMetricSortBy(this.name);
  final String name;

  int compare(BusinessMetric a, BusinessMetric b) {
    switch (this) {
      case BusinessMetricSortBy.nameAscending:
        return a.name.compareTo(b.name);
      case BusinessMetricSortBy.nameDescending:
        return b.name.compareTo(a.name);
      case BusinessMetricSortBy.currentValueAscending:
        return a.currentValue.compareTo(b.currentValue);
      case BusinessMetricSortBy.currentValueDescending:
        return b.currentValue.compareTo(a.currentValue);
      case BusinessMetricSortBy.previousValueAscending:
        return a.previousValue.compareTo(b.previousValue);
      case BusinessMetricSortBy.previousValueDescending:
        return b.previousValue.compareTo(a.previousValue);
      case BusinessMetricSortBy.percentageChangeAscending:
        return a.percentageChange.compareTo(b.percentageChange);
      case BusinessMetricSortBy.percentageChangeDescending:
        return b.percentageChange.compareTo(a.percentageChange);
    }
  }
}

/// Data class for product-specific sales trends
class ProductSalesTrend extends Equatable {
  const ProductSalesTrend({
    required this.date,
    required this.product,
    required this.quantitySold,
    required this.revenue,
    required this.profit,
  });

  final DateTime date;
  final Product product;
  final double quantitySold;
  final double revenue;
  final double profit;

  ProductSalesTrend copyWith({
    DateTime? date,
    Product? product,
    double? quantitySold,
    double? revenue,
    double? profit,
  }) {
    return ProductSalesTrend(
      date: date ?? this.date,
      product: product ?? this.product,
      quantitySold: quantitySold ?? this.quantitySold,
      revenue: revenue ?? this.revenue,
      profit: profit ?? this.profit,
    );
  }

  @override
  List<Object?> get props => [
        date,
        product,
        quantitySold,
        revenue,
        profit,
      ];
}

/// Data class for category-specific sales trends
class CategorySalesTrend extends Equatable {
  const CategorySalesTrend({
    required this.date,
    required this.category,
    required this.totalQuantitySold,
    required this.totalRevenue,
    required this.totalProfit,
  });

  final DateTime date;
  final Category category;
  final double totalQuantitySold;
  final double totalRevenue;
  final double totalProfit;

  CategorySalesTrend copyWith({
    DateTime? date,
    Category? category,
    double? totalQuantitySold,
    double? totalRevenue,
    double? totalProfit,
  }) {
    return CategorySalesTrend(
      date: date ?? this.date,
      category: category ?? this.category,
      totalQuantitySold: totalQuantitySold ?? this.totalQuantitySold,
      totalRevenue: totalRevenue ?? this.totalRevenue,
      totalProfit: totalProfit ?? this.totalProfit,
    );
  }

  @override
  List<Object?> get props => [
        date,
        category,
        totalQuantitySold,
        totalRevenue,
        totalProfit,
      ];
}

/// Data class for grouping product sales trends over time
class ProductSalesTrendSeries extends Equatable {
  const ProductSalesTrendSeries({
    required this.product,
    required this.trends,
  });

  final Product product;
  final List<ProductSalesTrend> trends;

  ProductSalesTrendSeries copyWith({
    Product? product,
    List<ProductSalesTrend>? trends,
  }) {
    return ProductSalesTrendSeries(
      product: product ?? this.product,
      trends: trends ?? this.trends,
    );
  }

  @override
  List<Object?> get props => [product, trends];
}

/// Data class for grouping category sales trends over time
class CategorySalesTrendSeries extends Equatable {
  const CategorySalesTrendSeries({
    required this.category,
    required this.trends,
  });

  final Category category;
  final List<CategorySalesTrend> trends;

  CategorySalesTrendSeries copyWith({
    Category? category,
    List<CategorySalesTrend>? trends,
  }) {
    return CategorySalesTrendSeries(
      category: category ?? this.category,
      trends: trends ?? this.trends,
    );
  }

  @override
  List<Object?> get props => [category, trends];
}

/// Query data for business snapshot report
class BusinessSnapshotQueryData extends Equatable {
  factory BusinessSnapshotQueryData.empty() {
    return BusinessSnapshotQueryData(
      currentPeriodStart: ReportsGlobals.defaultStartDate,
      currentPeriodEnd: ReportsGlobals.defaultEndDate,
    );
  }
  const BusinessSnapshotQueryData({
    required this.currentPeriodStart,
    required this.currentPeriodEnd,
    this.comparisonPeriod = BusinessSnapshotPeriod.month,
    this.topProductsSortBy = TopSellingProductSortBy.quantitySoldDescending,
    this.expenseBreakdownSortBy = ExpenseBreakdownSortBy.amountDescending,
    this.keyMetricsSortBy = BusinessMetricSortBy.currentValueDescending,
    this.topSellingProducts,
    this.expenseBreakdown,
    this.keyMetrics,
    this.revenueTrends,
    this.summary,
    this.productSalesTrendSeries = const [],
    this.categorySalesTrendSeries = const [],
    this.maxTopProducts = 10,
    this.selectedProducts = const [],
    this.selectedCategories = const [],
  });
  final DateTime currentPeriodStart;
  final DateTime currentPeriodEnd;
  final BusinessSnapshotPeriod comparisonPeriod;
  final TopSellingProductSortBy topProductsSortBy;
  final ExpenseBreakdownSortBy expenseBreakdownSortBy;
  final BusinessMetricSortBy keyMetricsSortBy;
  final List<TopSellingProduct>? topSellingProducts;
  final List<ExpenseBreakdown>? expenseBreakdown;
  final List<BusinessMetric>? keyMetrics;
  final List<RevenueTrend>? revenueTrends;
  final BusinessSummary? summary;
  final List<ProductSalesTrendSeries> productSalesTrendSeries;
  final List<CategorySalesTrendSeries> categorySalesTrendSeries;
  final int maxTopProducts; // Maximum number of top products to show
  final List<Product> selectedProducts; // Selected products for chart display
  final List<Category> selectedCategories; // Selected categories for chart display
  BusinessSnapshotQueryData Function({
    DateTime? currentPeriodStart,
    DateTime? currentPeriodEnd,
    BusinessSnapshotPeriod? comparisonPeriod,
    TopSellingProductSortBy? topProductsSortBy,
    ExpenseBreakdownSortBy? expenseBreakdownSortBy,
    BusinessMetricSortBy? keyMetricsSortBy,
    List<TopSellingProduct>? topSellingProducts,
    List<ExpenseBreakdown>? expenseBreakdown,
    List<BusinessMetric>? keyMetrics,
    List<RevenueTrend>? revenueTrends,
    BusinessSummary? summary,
    List<ProductSalesTrendSeries>? productSalesTrendSeries,
    List<CategorySalesTrendSeries>? categorySalesTrendSeries,
    int? maxTopProducts,
    List<Product>? selectedProducts,
    List<Category>? selectedCategories,
  }) get copyWith {
    return ({
      Object? currentPeriodStart = undefined,
      Object? currentPeriodEnd = undefined,
      Object? comparisonPeriod = undefined,
      Object? topProductsSortBy = undefined,
      Object? expenseBreakdownSortBy = undefined,
      Object? keyMetricsSortBy = undefined,
      Object? topSellingProducts = undefined,
      Object? expenseBreakdown = undefined,
      Object? keyMetrics = undefined,
      Object? revenueTrends = undefined,
      Object? summary = undefined,
      Object? productSalesTrendSeries = undefined,
      Object? categorySalesTrendSeries = undefined,
      Object? maxTopProducts = undefined,
      Object? selectedProducts = undefined,
      Object? selectedCategories = undefined,
    }) {
      return BusinessSnapshotQueryData(
        currentPeriodStart: currentPeriodStart.or(this.currentPeriodStart),
        currentPeriodEnd: currentPeriodEnd.or(this.currentPeriodEnd),
        comparisonPeriod: comparisonPeriod.or(this.comparisonPeriod),
        topProductsSortBy: topProductsSortBy.or(this.topProductsSortBy),
        expenseBreakdownSortBy: expenseBreakdownSortBy.or(this.expenseBreakdownSortBy),
        keyMetricsSortBy: keyMetricsSortBy.or(this.keyMetricsSortBy),
        topSellingProducts: topSellingProducts.or(this.topSellingProducts),
        expenseBreakdown: expenseBreakdown.or(this.expenseBreakdown),
        keyMetrics: keyMetrics.or(this.keyMetrics),
        revenueTrends: revenueTrends.or(this.revenueTrends),
        summary: summary.or(this.summary),
        productSalesTrendSeries: productSalesTrendSeries.or(this.productSalesTrendSeries),
        categorySalesTrendSeries: categorySalesTrendSeries.or(this.categorySalesTrendSeries),
        maxTopProducts: maxTopProducts.or(this.maxTopProducts),
        selectedProducts: selectedProducts.or(this.selectedProducts),
        selectedCategories: selectedCategories.or(this.selectedCategories),
      );
    };
  }

  @override
  List<Object?> get props => [
        currentPeriodStart,
        currentPeriodEnd,
        comparisonPeriod,
        topProductsSortBy,
        expenseBreakdownSortBy,
        keyMetricsSortBy,
        topSellingProducts,
        expenseBreakdown,
        keyMetrics,
        revenueTrends,
        summary,
        productSalesTrendSeries,
        categorySalesTrendSeries,
        maxTopProducts,
        selectedProducts,
        selectedCategories,
      ];
}
