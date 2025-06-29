import 'dart:typed_data';

import 'package:bloc/bloc.dart';
import 'package:easthardware_pms/domain/models/category.dart';
import 'package:easthardware_pms/domain/models/expense_type.dart';
import 'package:easthardware_pms/domain/models/invoice.dart';
import 'package:easthardware_pms/domain/models/invoice_product.dart';
import 'package:easthardware_pms/domain/models/order.dart';
import 'package:easthardware_pms/domain/models/order_product.dart';
import 'package:easthardware_pms/domain/models/product.dart';
import 'package:easthardware_pms/presentation/views/reports/business_snapshot/business_snapshot_query_data.dart';
import 'package:easthardware_pms/utils/num_iterable_extension.dart';
import 'package:easthardware_pms/utils/undefined.dart';
import 'package:equatable/equatable.dart';
import 'package:fluent_ui/fluent_ui.dart';

part 'business_snapshot_report_event.dart';
part 'business_snapshot_report_state.dart';

class BusinessSnapshotReportBloc
    extends Bloc<BusinessSnapshotReportEvent, BusinessSnapshotReportState> {
  BusinessSnapshotReportBloc(
    List<Product> products,
    List<Invoice> invoices,
    List<InvoiceProduct> invoiceProducts,
    List<Order> orders,
    List<OrderProduct> orderProducts,
    List<ExpenseType> expenseTypes,
  ) : super(BusinessSnapshotReportState(
          products: products,
          invoices: invoices,
          invoiceProducts: invoiceProducts,
          orders: orders,
          orderProducts: orderProducts,
          expenseTypes: expenseTypes,
          queryData: BusinessSnapshotQueryData.empty(),
        )) {
    on<BusinessSnapshotReportInitializeEvent>(_onInitialize);
    on<BusinessSnapshotReportSetGeneratingEvent>(_onSetGenerating);
    on<BusinessSnapshotReportSetStartDateEvent>(_onSetStartDate);
    on<BusinessSnapshotReportSetEndDateEvent>(_onSetEndDate);
    on<BusinessSnapshotReportSetComparisonPeriodEvent>(_onSetComparisonPeriod);
    on<BusinessSnapshotReportSetTopProductsSortByEvent>(_onSetTopProductsSortBy);
    on<BusinessSnapshotReportSetExpenseBreakdownSortByEvent>(_onSetExpenseBreakdownSortBy);
    on<BusinessSnapshotReportSetKeyMetricsSortByEvent>(_onSetKeyMetricsSortBy);
    on<BusinessSnapshotReportSetMaxTopProductsEvent>(_onSetMaxTopProducts);
    on<BusinessSnapshotReportSetOverlayEvent>(_onSetOverlay);
    on<BusinessSnapshotReportRemoveOverlayEvent>(_onRemoveOverlay);

    // Events to update data sources
    on<BusinessSnapshotReportUpdateProductsEvent>(_onUpdateProducts);
    on<BusinessSnapshotReportUpdateInvoicesEvent>(_onUpdateInvoices);
    on<BusinessSnapshotReportUpdateInvoiceProductsEvent>(_onUpdateInvoiceProducts);
    on<BusinessSnapshotReportUpdateOrdersEvent>(_onUpdateOrders);
    on<BusinessSnapshotReportUpdateOrderProductsEvent>(_onUpdateOrderProducts);
    on<BusinessSnapshotReportUpdateExpenseTypesEvent>(_onUpdateExpenseTypes);
    on<BusinessSnapshotReportSetChartImageEvent>(_onSetChartImage);

    // Product and Category Selection Events
    on<BusinessSnapshotReportSetSelectedProductsEvent>(_onSetSelectedProducts);
    on<BusinessSnapshotReportAddSelectedProductEvent>(_onAddSelectedProduct);
    on<BusinessSnapshotReportRemoveSelectedProductEvent>(_onRemoveSelectedProduct);
    on<BusinessSnapshotReportSetSelectedCategoriesEvent>(_onSetSelectedCategories);
    on<BusinessSnapshotReportAddSelectedCategoryEvent>(_onAddSelectedCategory);
    on<BusinessSnapshotReportRemoveSelectedCategoryEvent>(_onRemoveSelectedCategory);

    // Initialize the query data
    add(const BusinessSnapshotReportInitializeEvent());
  }

  Future<void> _onInitialize(
    BusinessSnapshotReportInitializeEvent event,
    Emitter<BusinessSnapshotReportState> emit,
  ) async {
    _recalculateBusinessSnapshotData(emit);
  }

  void _onSetGenerating(
    BusinessSnapshotReportSetGeneratingEvent event,
    Emitter<BusinessSnapshotReportState> emit,
  ) {
    emit(state.copyWith(isGenerating: event.isGenerating));
  }

  void _onSetStartDate(
    BusinessSnapshotReportSetStartDateEvent event,
    Emitter<BusinessSnapshotReportState> emit,
  ) {
    emit(state.copyWith(
      queryData: state.queryData.copyWith(currentPeriodStart: event.startDate),
    ));
    _recalculateBusinessSnapshotData(emit);
  }

  void _onSetEndDate(
    BusinessSnapshotReportSetEndDateEvent event,
    Emitter<BusinessSnapshotReportState> emit,
  ) {
    emit(state.copyWith(
      queryData: state.queryData.copyWith(currentPeriodEnd: event.endDate),
    ));
    _recalculateBusinessSnapshotData(emit);
  }

  void _onSetComparisonPeriod(
    BusinessSnapshotReportSetComparisonPeriodEvent event,
    Emitter<BusinessSnapshotReportState> emit,
  ) {
    emit(state.copyWith(
      queryData: state.queryData.copyWith(comparisonPeriod: event.comparisonPeriod),
    ));
    _recalculateBusinessSnapshotData(emit);
  }

  void _onSetTopProductsSortBy(
    BusinessSnapshotReportSetTopProductsSortByEvent event,
    Emitter<BusinessSnapshotReportState> emit,
  ) {
    emit(state.copyWith(
      queryData: state.queryData.copyWith(topProductsSortBy: event.sortBy),
    ));
    _recalculateBusinessSnapshotData(emit);
  }

  void _onSetExpenseBreakdownSortBy(
    BusinessSnapshotReportSetExpenseBreakdownSortByEvent event,
    Emitter<BusinessSnapshotReportState> emit,
  ) {
    emit(state.copyWith(
      queryData: state.queryData.copyWith(expenseBreakdownSortBy: event.sortBy),
    ));
    _recalculateBusinessSnapshotData(emit);
  }

  void _onSetKeyMetricsSortBy(
    BusinessSnapshotReportSetKeyMetricsSortByEvent event,
    Emitter<BusinessSnapshotReportState> emit,
  ) {
    emit(state.copyWith(
      queryData: state.queryData.copyWith(keyMetricsSortBy: event.sortBy),
    ));
    _recalculateBusinessSnapshotData(emit);
  }

  void _onSetMaxTopProducts(
    BusinessSnapshotReportSetMaxTopProductsEvent event,
    Emitter<BusinessSnapshotReportState> emit,
  ) {
    emit(state.copyWith(
      queryData: state.queryData.copyWith(maxTopProducts: event.maxProducts),
    ));
    _recalculateBusinessSnapshotData(emit);
  }

  void _onSetOverlay(
    BusinessSnapshotReportSetOverlayEvent event,
    Emitter<BusinessSnapshotReportState> emit,
  ) {
    emit(state.copyWith(overlayEntry: event.overlayEntry));
  }

  void _onRemoveOverlay(
    BusinessSnapshotReportRemoveOverlayEvent event,
    Emitter<BusinessSnapshotReportState> emit,
  ) {
    final overlay = state.overlayEntry;
    overlay?.remove();
    emit(state.copyWith(overlayEntry: null));
  }

  void _onUpdateProducts(
    BusinessSnapshotReportUpdateProductsEvent event,
    Emitter<BusinessSnapshotReportState> emit,
  ) {
    emit(state.copyWith(products: event.products));
    _recalculateBusinessSnapshotData(emit);
  }

  void _onUpdateInvoices(
    BusinessSnapshotReportUpdateInvoicesEvent event,
    Emitter<BusinessSnapshotReportState> emit,
  ) {
    emit(state.copyWith(invoices: event.invoices));
    _recalculateBusinessSnapshotData(emit);
  }

  void _onUpdateInvoiceProducts(
    BusinessSnapshotReportUpdateInvoiceProductsEvent event,
    Emitter<BusinessSnapshotReportState> emit,
  ) {
    emit(state.copyWith(invoiceProducts: event.invoiceProducts));
    _recalculateBusinessSnapshotData(emit);
  }

  void _onUpdateOrders(
    BusinessSnapshotReportUpdateOrdersEvent event,
    Emitter<BusinessSnapshotReportState> emit,
  ) {
    emit(state.copyWith(orders: event.orders));
    _recalculateBusinessSnapshotData(emit);
  }

  void _onUpdateOrderProducts(
    BusinessSnapshotReportUpdateOrderProductsEvent event,
    Emitter<BusinessSnapshotReportState> emit,
  ) {
    emit(state.copyWith(orderProducts: event.orderProducts));
    _recalculateBusinessSnapshotData(emit);
  }

  void _onUpdateExpenseTypes(
    BusinessSnapshotReportUpdateExpenseTypesEvent event,
    Emitter<BusinessSnapshotReportState> emit,
  ) {
    emit(state.copyWith(expenseTypes: event.expenseTypes));
    _recalculateBusinessSnapshotData(emit);
  }

  void _onSetChartImage(
    BusinessSnapshotReportSetChartImageEvent event,
    Emitter<BusinessSnapshotReportState> emit,
  ) {
    emit(state.copyWith(chartImage: event.chartImage));
  }

  // Product and Category Selection Event Handlers
  void _onSetSelectedProducts(
    BusinessSnapshotReportSetSelectedProductsEvent event,
    Emitter<BusinessSnapshotReportState> emit,
  ) {
    emit(state.copyWith(
      queryData: state.queryData.copyWith(selectedProducts: event.selectedProducts),
    ));
    _recalculateBusinessSnapshotData(emit);
  }

  void _onAddSelectedProduct(
    BusinessSnapshotReportAddSelectedProductEvent event,
    Emitter<BusinessSnapshotReportState> emit,
  ) {
    final currentProducts = List<Product>.from(state.queryData.selectedProducts);
    if (!currentProducts.any((p) => p.id == event.product.id)) {
      currentProducts.add(event.product);
      emit(state.copyWith(
        queryData: state.queryData.copyWith(selectedProducts: currentProducts),
      ));
      _recalculateBusinessSnapshotData(emit);
    }
  }

  void _onRemoveSelectedProduct(
    BusinessSnapshotReportRemoveSelectedProductEvent event,
    Emitter<BusinessSnapshotReportState> emit,
  ) {
    final currentProducts = List<Product>.from(state.queryData.selectedProducts);
    currentProducts.removeWhere((p) => p.id == event.product.id);
    emit(state.copyWith(
      queryData: state.queryData.copyWith(selectedProducts: currentProducts),
    ));
    _recalculateBusinessSnapshotData(emit);
  }

  void _onSetSelectedCategories(
    BusinessSnapshotReportSetSelectedCategoriesEvent event,
    Emitter<BusinessSnapshotReportState> emit,
  ) {
    emit(state.copyWith(
      queryData: state.queryData.copyWith(selectedCategories: event.selectedCategories),
    ));
    _recalculateBusinessSnapshotData(emit);
  }

  void _onAddSelectedCategory(
    BusinessSnapshotReportAddSelectedCategoryEvent event,
    Emitter<BusinessSnapshotReportState> emit,
  ) {
    final currentCategories = List<Category>.from(state.queryData.selectedCategories);
    if (!currentCategories.any((c) => c.id == event.category.id)) {
      currentCategories.add(event.category);
      emit(state.copyWith(
        queryData: state.queryData.copyWith(selectedCategories: currentCategories),
      ));
      _recalculateBusinessSnapshotData(emit);
    }
  }

  void _onRemoveSelectedCategory(
    BusinessSnapshotReportRemoveSelectedCategoryEvent event,
    Emitter<BusinessSnapshotReportState> emit,
  ) {
    final currentCategories = List<Category>.from(state.queryData.selectedCategories);
    currentCategories.removeWhere((c) => c.id == event.category.id);
    emit(state.copyWith(
      queryData: state.queryData.copyWith(selectedCategories: currentCategories),
    ));
    _recalculateBusinessSnapshotData(emit);
  }

  void _recalculateBusinessSnapshotData(Emitter<BusinessSnapshotReportState> emit) {
    final products = state.products;
    final invoices = state.invoices;
    final invoiceProducts = state.invoiceProducts;
    final orders = state.orders;
    final expenseTypes = state.expenseTypes;

    final currentPeriodStart = state.queryData.currentPeriodStart;
    final currentPeriodEnd =
        state.queryData.currentPeriodEnd.add(const Duration(days: 1)); // Include end date
    final topProductsSortBy = state.queryData.topProductsSortBy;
    final expenseBreakdownSortBy = state.queryData.expenseBreakdownSortBy;
    final keyMetricsSortBy = state.queryData.keyMetricsSortBy;
    final maxTopProducts = state.queryData.maxTopProducts;

    // Calculate previous period dates based on comparison period
    final duration = currentPeriodEnd.difference(currentPeriodStart);
    final previousPeriodEnd = currentPeriodStart;
    final previousPeriodStart = previousPeriodEnd.subtract(duration);

    // Filter invoices and orders for current and previous periods
    final currentInvoices = invoices.where((invoice) {
      return invoice.invoiceDate.isAfter(currentPeriodStart) &&
          invoice.invoiceDate.isBefore(currentPeriodEnd);
    }).toList();

    final previousInvoices = invoices.where((invoice) {
      return invoice.invoiceDate.isAfter(previousPeriodStart) &&
          invoice.invoiceDate.isBefore(previousPeriodEnd);
    }).toList();

    final currentOrders = orders.where((order) {
      return order.orderDate.isAfter(currentPeriodStart) &&
          order.orderDate.isBefore(currentPeriodEnd);
    }).toList();

    final previousOrders = orders.where((order) {
      return order.orderDate.isAfter(previousPeriodStart) &&
          order.orderDate.isBefore(previousPeriodEnd);
    }).toList();

    // Calculate key metrics
    final currentRevenue = currentInvoices.map((invoice) {
      final invoiceProducts =
          state.invoiceProducts.where((ip) => ip.invoiceId == invoice.id).toList();
      return invoiceProducts.map((ip) => ip.rate * ip.quantity).sum();
    }).sum();

    final previousRevenue = previousInvoices.map((invoice) {
      final invoiceProducts =
          state.invoiceProducts.where((ip) => ip.invoiceId == invoice.id).toList();
      return invoiceProducts.map((ip) => ip.rate * ip.quantity).sum();
    }).sum();

    final currentExpenses = currentOrders.map((order) => order.amountDue).sum();
    final previousExpenses = previousOrders.map((order) => order.amountDue).sum();

    final currentProfit = currentRevenue - currentExpenses;
    final previousProfit = previousRevenue - previousExpenses;

    final currentProfitMargin = currentRevenue > 0 //
        ? (currentProfit / currentRevenue) * 100
        : 0.0;
    final previousProfitMargin = previousRevenue > 0 //
        ? (previousProfit / previousRevenue) * 100
        : 0.0;

    final currentAvgOrderValue = currentInvoices.isNotEmpty //
        ? currentRevenue / currentInvoices.length
        : 0.0;
    final previousAvgOrderValue = previousInvoices.isNotEmpty //
        ? previousRevenue / previousInvoices.length
        : 0.0;

    // Calculate inventory metrics
    final lowStockProducts = products.where((p) => p.quantity <= p.criticalLevel).length;
    final previousLowStockCount = lowStockProducts; // Assume no historical data for now

    // Create key metrics list
    final keyMetrics = <BusinessMetric>[
      BusinessMetric(
        name: 'Total Revenue',
        currentValue: currentRevenue,
        previousValue: previousRevenue,
        percentageChange: previousRevenue > 0
            ? ((currentRevenue - previousRevenue) / previousRevenue) * 100
            : 100,
        isPositiveTrend: true,
      ),
      BusinessMetric(
        name: 'Total Expenses',
        currentValue: currentExpenses,
        previousValue: previousExpenses,
        percentageChange: previousExpenses > 0
            ? ((currentExpenses - previousExpenses) / previousExpenses) * 100
            : 100,
        isPositiveTrend: false, // Lower expenses are better
      ),
      BusinessMetric(
        name: 'Net Profit',
        currentValue: currentProfit,
        previousValue: previousProfit,
        percentageChange:
            previousProfit > 0 ? ((currentProfit - previousProfit) / previousProfit) * 100 : 100,
        isPositiveTrend: true,
      ),
      BusinessMetric(
        name: 'Profit Margin',
        currentValue: currentProfitMargin,
        previousValue: previousProfitMargin,
        percentageChange: previousProfitMargin > 0
            ? (currentProfitMargin - previousProfitMargin)
            : currentProfitMargin,
        isPositiveTrend: true,
      ),
      BusinessMetric(
        name: 'Average Order Value',
        currentValue: currentAvgOrderValue,
        previousValue: previousAvgOrderValue,
        percentageChange: previousAvgOrderValue > 0
            ? ((currentAvgOrderValue - previousAvgOrderValue) / previousAvgOrderValue) * 100
            : 100,
        isPositiveTrend: true,
      ),
      BusinessMetric(
        name: 'Low Stock Products',
        currentValue: lowStockProducts.toDouble(),
        previousValue: previousLowStockCount.toDouble(),
        percentageChange: previousLowStockCount > 0
            ? ((lowStockProducts - previousLowStockCount) / previousLowStockCount) * 100
            : 0,
        isPositiveTrend: false, // Lower low stock count is better
      ),
      BusinessMetric(
        name: 'Order Count',
        currentValue: currentInvoices.length.toDouble(),
        previousValue: previousInvoices.length.toDouble(),
        percentageChange: previousInvoices.isNotEmpty
            ? ((currentInvoices.length - previousInvoices.length) / previousInvoices.length) * 100
            : 100,
        isPositiveTrend: true,
      ),
    ];

    // Sort key metrics
    keyMetrics.sort(keyMetricsSortBy.compare);

    // Calculate top selling products
    final productSales = <int, TopSellingProduct>{};

    for (final invoice in currentInvoices) {
      for (final ip in invoiceProducts.where((ip) => ip.invoiceId == invoice.id)) {
        final product = products.where((p) => p.id == ip.productId).firstOrNull;
        if (product == null) continue;

        final id = product.id;
        if (id == null) continue;

        final revenue = ip.rate * ip.quantity;
        final cost = product.orderCost * ip.quantity;
        final profit = revenue - cost;

        if (productSales.containsKey(id)) {
          final existing = productSales[id]!;
          productSales[id] = existing.copyWith(
            quantitySold: existing.quantitySold + ip.quantity,
            revenue: existing.revenue + revenue,
            profit: existing.profit + profit,
          );
        } else {
          productSales[id] = TopSellingProduct(
            product: product,
            quantitySold: ip.quantity * (ip.conversionFactor ?? 1.0),
            revenue: revenue,
            profit: profit,
          );
        }
      }
    }

    final topSellingProducts = productSales.values.toList();
    topSellingProducts.sort(topProductsSortBy.compare);

    // Limit to max number of products
    final limitedTopProducts = topSellingProducts.take(maxTopProducts).toList();

    // Calculate expense breakdown
    final expenseMap = <int, ExpenseBreakdown>{};
    final totalExpensesAmount = currentExpenses;

    for (final order in currentOrders) {
      final expenseType = expenseTypes.firstWhere(
        (et) => et.id == order.expenseType,
        orElse: () => const ExpenseType(name: 'Unknown'),
      );

      final expenseAmount = order.amountDue;

      if (expenseMap.containsKey(expenseType.id)) {
        final existing = expenseMap[expenseType.id]!;
        expenseMap[expenseType.id!] = existing.copyWith(
          amount: existing.amount + expenseAmount,
          percentage: ((existing.amount + expenseAmount) / totalExpensesAmount) * 100,
        );
      } else {
        expenseMap[expenseType.id!] = ExpenseBreakdown(
          expenseType: expenseType,
          amount: expenseAmount,
          percentage: (expenseAmount / totalExpensesAmount) * 100,
        );
      }
    }

    final expenseBreakdown = expenseMap.values.toList();
    expenseBreakdown.sort(expenseBreakdownSortBy.compare);

    // Generate revenue trends
    // Calculate the number of data points based on the date range
    final daysDifference = currentPeriodEnd.difference(currentPeriodStart).inDays;
    final revenueTrends = <RevenueTrend>[];

    // Create a reasonable number of data points
    var dataPoints = 12; // Default for monthly view
    if (daysDifference < 14) {
      dataPoints = daysDifference; // Daily view for short periods
    } else if (daysDifference < 60) {
      dataPoints = daysDifference ~/ 2; // Every 2 days for medium periods
    } else if (daysDifference > 180) {
      dataPoints = 24; // Every other week for long periods
    }

    final interval = daysDifference / dataPoints;

    for (var i = 0; i < dataPoints; i++) {
      final date = currentPeriodStart.add(Duration(days: (i * interval).round()));
      final endDate = i < dataPoints - 1
          ? currentPeriodStart.add(Duration(days: ((i + 1) * interval).round()))
          : currentPeriodEnd;

      // Calculate revenue for this period
      var periodRevenue = 0.0;
      var periodExpenses = 0.0;

      for (final invoice in currentInvoices) {
        if (invoice.invoiceDate.isAfter(date) && invoice.invoiceDate.isBefore(endDate)) {
          final invoiceProducts =
              state.invoiceProducts.where((ip) => ip.invoiceId == invoice.id).toList();
          periodRevenue += invoiceProducts.map((ip) => ip.rate * ip.quantity).sum();
        }
      }

      for (final order in currentOrders) {
        if (order.orderDate.isAfter(date) && order.orderDate.isBefore(endDate)) {
          periodExpenses += order.amountDue;
        }
      }

      final periodProfit = periodRevenue - periodExpenses;

      revenueTrends.add(RevenueTrend(
        date: date,
        revenue: periodRevenue,
        expenses: periodExpenses,
        profit: periodProfit,
      ));
    } // Create business summary
    final summary = BusinessSummary(
      totalRevenue: currentRevenue,
      totalExpenses: currentExpenses,
      totalProfit: currentProfit,
      profitMargin: currentProfitMargin,
      totalProducts: products.length,
      lowStockProducts: lowStockProducts,
      totalOrders: currentInvoices.length,
      pendingOrders: orders.where((o) => (o.amountPaid ?? 0) < o.amountDue).length,
    ); // Calculate product sales trends for selected products
    final productSalesTrendSeries = <ProductSalesTrendSeries>[];
    for (final selectedProduct in state.queryData.selectedProducts) {
      final productTrends = <ProductSalesTrend>[];

      for (var i = 0; i < dataPoints; i++) {
        final date = currentPeriodStart.add(Duration(days: (i * interval).round()));
        final endDate = i < dataPoints - 1
            ? currentPeriodStart.add(Duration(days: ((i + 1) * interval).round()))
            : currentPeriodEnd;

        var periodSales = 0.0;
        var periodQuantity = 0.0;
        for (final invoice in currentInvoices) {
          if (invoice.invoiceDate.isAfter(date) && invoice.invoiceDate.isBefore(endDate)) {
            final productInvoices = invoiceProducts
                .where((ip) => ip.invoiceId == invoice.id && ip.productId == selectedProduct.id)
                .toList();
            periodSales += productInvoices.map((ip) => ip.rate * ip.quantity).sum();
            periodQuantity += productInvoices.map((ip) => ip.quantity).sum();
          }
        }

        productTrends.add(ProductSalesTrend(
          date: date,
          product: selectedProduct,
          quantitySold: periodQuantity,
          revenue: periodSales,
          profit: periodSales, // Simplified - just sales revenue
        ));
      }

      productSalesTrendSeries.add(ProductSalesTrendSeries(
        product: selectedProduct,
        trends: productTrends,
      ));
    }

    // Calculate category sales trends for selected categories
    final categorySalesTrendSeries = <CategorySalesTrendSeries>[];
    for (final selectedCategory in state.queryData.selectedCategories) {
      final categoryTrends = <CategorySalesTrend>[];
      final categoryProducts = products.where((p) => p.categoryId == selectedCategory.id).toList();

      for (var i = 0; i < dataPoints; i++) {
        final date = currentPeriodStart.add(Duration(days: (i * interval).round()));
        final endDate = i < dataPoints - 1
            ? currentPeriodStart.add(Duration(days: ((i + 1) * interval).round()))
            : currentPeriodEnd;

        var periodSales = 0.0;
        var periodQuantity = 0.0;
        for (final invoice in currentInvoices) {
          if (invoice.invoiceDate.isAfter(date) && invoice.invoiceDate.isBefore(endDate)) {
            final categoryInvoices = invoiceProducts
                .where((ip) =>
                    ip.invoiceId == invoice.id && categoryProducts.any((p) => p.id == ip.productId))
                .toList();
            periodSales += categoryInvoices.map((ip) => ip.rate * ip.quantity).sum();
            periodQuantity += categoryInvoices.map((ip) => ip.quantity).sum();
          }
        }

        categoryTrends.add(CategorySalesTrend(
          date: date,
          category: selectedCategory,
          totalQuantitySold: periodQuantity,
          totalRevenue: periodSales,
          totalProfit: periodSales, // Simplified - just sales revenue
        ));
      }

      categorySalesTrendSeries.add(CategorySalesTrendSeries(
        category: selectedCategory,
        trends: categoryTrends,
      ));
    }
    emit(state.copyWith(
      queryData: state.queryData.copyWith(
        topSellingProducts: limitedTopProducts,
        expenseBreakdown: expenseBreakdown,
        keyMetrics: keyMetrics,
        revenueTrends: revenueTrends,
        summary: summary,
        productSalesTrendSeries: productSalesTrendSeries,
        categorySalesTrendSeries: categorySalesTrendSeries,
      ),
    ));
  }
}
