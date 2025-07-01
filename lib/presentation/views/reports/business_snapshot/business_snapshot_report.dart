import 'dart:async';
import 'dart:ui';

import 'package:easthardware_pms/domain/models/category.dart';
import 'package:easthardware_pms/domain/models/product.dart';
import 'package:easthardware_pms/presentation/bloc/business_snapshot/'
    'business_snapshot_report_bloc.dart';
import 'package:easthardware_pms/presentation/router/app_routes.dart';
import 'package:easthardware_pms/presentation/views/reports/'
    'business_snapshot/business_snapshot_query_data.dart';
import 'package:easthardware_pms/presentation/views/reports/pdf_helpers/pdf_commons.dart';
import 'package:easthardware_pms/presentation/views/reports/pdf_helpers/pdf_generation.dart';
import 'package:easthardware_pms/presentation/widgets/animated_single_child_scroll_view.dart';
import 'package:easthardware_pms/presentation/widgets/bordered_date_picker.dart';
import 'package:easthardware_pms/presentation/widgets/helper/currency_formatter.dart';
import 'package:easthardware_pms/presentation/widgets/layout/spacing.dart';
import 'package:easthardware_pms/presentation/widgets/text.dart';
import 'package:easthardware_pms/presentation/widgets/ui/text_button.dart';
import 'package:easthardware_pms/utils/compare_lowercase.dart';
import 'package:easthardware_pms/utils/notification.dart';
import 'package:easthardware_pms/utils/num_iterable_extension.dart';
import 'package:easthardware_pms/utils/typed_routes.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Business Snapshot Report Page
/// This page displays a comprehensive snapshot of business performance
class BusinessSnapshotReport extends StatefulWidget {
  const BusinessSnapshotReport({super.key});

  @override
  State<BusinessSnapshotReport> createState() => _BusinessSnapshotReportState();
}

class _BusinessSnapshotReportState extends State<BusinessSnapshotReport> {
  final GlobalKey _chartKey = GlobalKey();

  @override
  void initState() {
    super.initState();

    context //
        .read<BusinessSnapshotReportBloc>()
        .add(const BusinessSnapshotReportInitializeEvent());
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BusinessSnapshotReportBloc, BusinessSnapshotReportState>(
      builder: (context, state) {
        return Padding(
          padding: AppPadding.panePadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _Header(),
              Spacing.v16,
              Expanded(
                child: AnimatedSingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildFilters(context, state),
                      _buildKeyMetricsSection(context, state),
                      _buildTopProductsSection(context, state),
                      _buildExpenseBreakdownSection(context, state),
                      _buildSalesHistorySection(context, state),
                    ].withSpacing(() => Spacing.v16),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilters(BuildContext context, BusinessSnapshotReportState state) {
    return Card(
      child: Padding(
        padding: AppPadding.cardPadding,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SubheadingText('Report Filters'),
                  Spacing.v8,
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(width: 80, child: Text('Start Date: ')),
                      Spacing.h8,
                      Flexible(
                        child: BorderedDatePicker(
                          selected: state.queryData.currentPeriodStart,
                          onChanged: (date) {
                            context
                                .read<BusinessSnapshotReportBloc>()
                                .add(BusinessSnapshotReportSetStartDateEvent(date));
                          },
                        ),
                      ),
                    ],
                  ),
                  Spacing.v8,
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(width: 80, child: Text('End Date: ')),
                      Spacing.h8,
                      Flexible(
                        child: BorderedDatePicker(
                          selected: state.queryData.currentPeriodEnd,
                          onChanged: (date) {
                            context
                                .read<BusinessSnapshotReportBloc>()
                                .add(BusinessSnapshotReportSetEndDateEvent(date));
                          },
                        ),
                      ),
                    ],
                  ),
                  Spacing.v16,
                  Row(
                    children: [
                      const Text('Comparison Period:'),
                      Spacing.h8,
                      ComboBox<BusinessSnapshotPeriod>(
                        value: state.queryData.comparisonPeriod,
                        items: [
                          for (final period in BusinessSnapshotPeriod.values)
                            ComboBoxItem<BusinessSnapshotPeriod>(
                              value: period,
                              child: Text(period.name),
                            ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            context
                                .read<BusinessSnapshotReportBloc>()
                                .add(BusinessSnapshotReportSetComparisonPeriodEvent(value));
                          }
                        },
                      ),
                    ],
                  ),
                  Spacing.v8,
                  _buildProductSelectionSection(context, state),
                  Spacing.v8,
                  _buildCategorySelectionSection(context, state),
                ],
              ),
            ),
            Spacing.h16,
            BlocBuilder<BusinessSnapshotReportBloc, BusinessSnapshotReportState>(
              builder: (context, reportState) {
                return TextButtonFilled(
                  'Generate Business Snapshot Report',
                  onPressed: reportState.isGenerating
                      ? null
                      : () => unawaited(_generatePdfReport(context, reportState)),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKeyMetricsSection(BuildContext context, BusinessSnapshotReportState state) {
    final metrics = state.queryData.keyMetrics ?? [];

    return Card(
      child: Padding(
        padding: AppPadding.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SubheadingText('Key Business Metrics'),
                Spacing.v8,
                Row(
                  children: [
                    const Text('Sort by:'),
                    Spacing.h8,
                    ComboBox<BusinessMetricSortBy>(
                      value: state.queryData.keyMetricsSortBy,
                      items: [
                        for (final value in BusinessMetricSortBy.values)
                          ComboBoxItem<BusinessMetricSortBy>(
                            value: value,
                            child: Text(value.name),
                          ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          context.read<BusinessSnapshotReportBloc>().add(
                                BusinessSnapshotReportSetKeyMetricsSortByEvent(value),
                              );
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
            Spacing.v16,
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 2.5,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: metrics.length,
              itemBuilder: (context, index) {
                final metric = metrics[index];
                return _buildMetricCard(metric);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(BusinessMetric metric) {
    final trendIcon = metric.isPositiveChange
        ? Icon(FluentIcons.chevron_up, color: Colors.green)
        : Icon(FluentIcons.chevron_down, color: Colors.red);

    return Card(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(metric.name, style: const TextStyle(fontWeight: FontWeight.bold)),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                CurrencyFormatter.full(metric.currentValue),
                style: const TextStyle(fontSize: 16),
              ),
              Row(
                children: [
                  trendIcon,
                  Spacing.h4,
                  Text(
                    '${metric.percentageChange.abs().toStringAsFixed(1)}%',
                    style: TextStyle(
                      color: metric.isPositiveChange ? Colors.green : Colors.red,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTopProductsSection(BuildContext context, BusinessSnapshotReportState state) {
    final topProducts = state.queryData.topSellingProducts ?? [];

    return Card(
      child: Padding(
        padding: AppPadding.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SubheadingText('Top Performing Products'),
                Spacing.v8,
                Row(
                  children: [
                    const Text('Sort by:'),
                    Spacing.h8,
                    Flexible(
                      child: ComboBox<TopSellingProductSortBy>(
                        value: state.queryData.topProductsSortBy,
                        items: [
                          for (final option in TopSellingProductSortBy.values)
                            ComboBoxItem<TopSellingProductSortBy>(
                              value: option,
                              child: Text(option.name),
                            ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            context //
                                .read<BusinessSnapshotReportBloc>()
                                .add(BusinessSnapshotReportSetTopProductsSortByEvent(value));
                          }
                        },
                      ),
                    )
                  ],
                ),
                Spacing.v8,
                Row(
                  children: [
                    const Text('Show (Minimum 3):'),
                    Spacing.h8,
                    ConstrainedBox(
                      constraints: const BoxConstraints(
                        minWidth: 120,
                        maxWidth: 180,
                      ),
                      child: NumberBox<int>(
                        value: state.queryData.maxTopProducts,
                        min: 3,
                        max: 20,
                        mode: SpinButtonPlacementMode.none,
                        clearButton: false,
                        onChanged: (value) {
                          if (value != null) {
                            context
                                .read<BusinessSnapshotReportBloc>()
                                .add(BusinessSnapshotReportSetMaxTopProductsEvent(value));
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Spacing.v16,
            Table(
              border: TableBorder.all(color: Colors.grey[30]),
              columnWidths: const {
                0: FlexColumnWidth(2),
                1: FlexColumnWidth(1),
                2: FlexColumnWidth(1),
                3: FlexColumnWidth(1),
              },
              children: [
                const TableRow(
                  decoration: BoxDecoration(color: Colors.white),
                  children: [
                    TableCell(
                      child: Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text('Product Name', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                    TableCell(
                      child: Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text('Quantity Sold', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                    TableCell(
                      child: Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text('Revenue', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                    TableCell(
                      child: Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text('Profit', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
                for (final product in topProducts)
                  TableRow(
                    children: [
                      TableCell(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(product.product.name),
                        ),
                      ),
                      TableCell(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(product.quantitySold.toStringAsFixed(2)),
                        ),
                      ),
                      TableCell(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(CurrencyFormatter.full(product.revenue)),
                        ),
                      ),
                      TableCell(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(CurrencyFormatter.full(product.profit)),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpenseBreakdownSection(BuildContext context, BusinessSnapshotReportState state) {
    final expenses = state.queryData.expenseBreakdown ?? [];

    return Container(
      color: FluentTheme.of(context).cardColor,
      padding: AppPadding.cardPadding,
      child: Padding(
        padding: AppPadding.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SubheadingText('Expense Breakdown'),
                Spacing.v8,
                Row(
                  children: [
                    const Text('Sort by:'),
                    Spacing.h8,
                    Flexible(
                      child: ComboBox<ExpenseBreakdownSortBy>(
                        value: state.queryData.expenseBreakdownSortBy,
                        items: [
                          for (final option in ExpenseBreakdownSortBy.values)
                            ComboBoxItem<ExpenseBreakdownSortBy>(
                              value: option,
                              child: Text(option.name),
                            ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            context.read<BusinessSnapshotReportBloc>().add(
                                  BusinessSnapshotReportSetExpenseBreakdownSortByEvent(value),
                                );
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Spacing.v16,
            Table(
              border: TableBorder.all(color: Colors.grey[30]),
              columnWidths: const {
                0: FlexColumnWidth(2),
                1: FlexColumnWidth(1),
                2: FlexColumnWidth(1),
              },
              children: [
                const TableRow(
                  decoration: BoxDecoration(color: Colors.white),
                  children: [
                    TableCell(
                      child: Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text('Expense Type', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                    TableCell(
                      child: Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text('Amount', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                    TableCell(
                      child: Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text('Percentage', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
                for (final expense in expenses)
                  TableRow(
                    children: [
                      TableCell(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(expense.expenseType.name),
                        ),
                      ),
                      TableCell(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(CurrencyFormatter.full(expense.amount)),
                        ),
                      ),
                      TableCell(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text('${expense.percentage.toStringAsFixed(1)}%'),
                        ),
                      ),
                    ],
                  ),
                TableRow(
                  decoration: const BoxDecoration(color: Colors.white),
                  children: [
                    const TableCell(
                      child: Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text('Total', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                    TableCell(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          CurrencyFormatter.full(
                            expenses.fold(0, (sum, expense) => sum + expense.amount),
                          ),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    TableCell(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          '${expenses.fold<double>(0, (sum, expense) => sum + expense.percentage).toStringAsFixed(1)}%',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSalesHistorySection(BuildContext context, BusinessSnapshotReportState state) {
    final revenueTrends = state.queryData.revenueTrends ?? [];

    return Card(
      child: Padding(
        padding: AppPadding.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SubheadingText('Sales History'),
            Spacing.v16,
            if (revenueTrends.isNotEmpty)
              RepaintBoundary(
                key: _chartKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Legend
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: _buildChartLegend(state.queryData),
                    ), // Chart
                    _SalesHistoryChart(
                      revenueTrends: revenueTrends,
                      queryData: state.queryData,
                    ),
                  ],
                ),
              )
            else
              RepaintBoundary(
                key: _chartKey,
                child: const SizedBox(
                  height: 300,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(FluentIcons.chart_template, size: 48, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No sales data available for the selected period',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartLegend(BusinessSnapshotQueryData queryData) {
    final legendItems = <Widget>[]; // Always include the base revenue, expenses, and profit lines
    legendItems.addAll([
      _LegendItem(color: Colors.green, label: 'Revenue'),
      const SizedBox(width: 16),
      _LegendItem(color: Colors.red, label: 'Expenses'),
      const SizedBox(width: 16),
      _LegendItem(color: Colors.blue, label: 'Profit'),
    ]);

    // Add product lines
    final productSeries = queryData.productSalesTrendSeries;
    final productColors = [
      const Color(0xFF9C27B0), // Purple
      const Color(0xFFFF9800), // Orange
      const Color(0xFF009688), // Teal
      const Color(0xFFE91E63), // Pink
      const Color(0xFF3F51B5), // Indigo
      const Color(0xFF795548), // Brown
      const Color(0xFFFF5722), // Deep Orange
      const Color(0xFF00BCD4), // Cyan
    ];

    for (var i = 0; i < productSeries.length && i < productColors.length; i++) {
      legendItems.addAll([
        const SizedBox(width: 16),
        _LegendItem(
          color: productColors[i],
          label: productSeries[i].product.name,
        ),
      ]);
    }

    // Add category lines
    final categorySeries = queryData.categorySalesTrendSeries;
    final categoryColors = [
      const Color(0xFFCDDC39), // Lime
      const Color(0xFFFFC107), // Amber
      const Color(0xFF673AB7), // Deep Purple
      const Color(0xFF607D8B), // Blue Grey
      const Color(0xFF8BC34A), // Light Green
      const Color(0xFFF44336), // Red Accent
      const Color(0xFFFFEB3B), // Yellow Accent
      const Color(0xFF03A9F4), // Light Blue
    ];

    for (var i = 0; i < categorySeries.length && i < categoryColors.length; i++) {
      legendItems.addAll([
        const SizedBox(width: 16),
        _LegendItem(
          color: categoryColors[i],
          label: categorySeries[i].category.name,
        ),
      ]);
    }

    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: legendItems,
    );
  }

  Widget _buildProductSelectionSection(BuildContext context, BusinessSnapshotReportState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Selected Products for Chart:'),
        Spacing.v8,
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            ...state.queryData.selectedProducts.map((product) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(product.name, style: const TextStyle(fontSize: 12)),
                      Spacing.h4,
                      IconButton(
                        icon: const Icon(FluentIcons.cancel, size: 12),
                        onPressed: () {
                          context
                              .read<BusinessSnapshotReportBloc>()
                              .add(BusinessSnapshotReportRemoveSelectedProductEvent(product));
                        },
                      ),
                    ],
                  ),
                )),
            TextButton(
              'Add Product',
              icon: FluentIcons.add,
              onPressed: () => unawaited(_showProductSelectionDialog(context, state)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCategorySelectionSection(BuildContext context, BusinessSnapshotReportState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Selected Categories for Chart:'),
        Spacing.v8,
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            for (final category in state.queryData.selectedCategories)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(category.name, style: const TextStyle(fontSize: 12)),
                    Spacing.h4,
                    IconButton(
                      icon: const Icon(FluentIcons.cancel, size: 12),
                      onPressed: () {
                        context
                            .read<BusinessSnapshotReportBloc>()
                            .add(BusinessSnapshotReportRemoveSelectedCategoryEvent(category));
                      },
                    ),
                  ],
                ),
              ),
            TextButton(
              'Add Product',
              icon: FluentIcons.add,
              onPressed: () => unawaited(_showCategorySelectionDialog(context, state)),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _showProductSelectionDialog(
    BuildContext context,
    BusinessSnapshotReportState state,
  ) async {
    final availableProducts = state.products
        .where((p) => !state.queryData.selectedProducts.any((s) => s.id == p.id))
        .toList()
      ..sort((a, b) => a.name.compareToLowercase(b.name));

    if (availableProducts.isEmpty) {
      showNotification(
        title: 'No Products Available',
        message: 'All products are already selected or no products exist.',
        severity: InfoBarSeverity.info,
      );
      return;
    }

    Product? selectedProduct;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => ContentDialog(
        title: const Text('Select Product'),
        content: StatefulBuilder(builder: (context, setState) {
          return ComboBox<Product>(
            placeholder: const Text('Choose a product...'),
            value: selectedProduct,
            items: [
              for (final product in availableProducts)
                ComboBoxItem<Product>(
                  value: product,
                  child: Text(product.name),
                ),
            ],
            onChanged: (value) => setState(() => selectedProduct = value),
          );
        }),
        actions: [
          Button(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(dialogContext).pop(),
          ),
          FilledButton(
            child: const Text('Add'),
            onPressed: () {
              if (selectedProduct != null) {
                context
                    .read<BusinessSnapshotReportBloc>()
                    .add(BusinessSnapshotReportAddSelectedProductEvent(selectedProduct!));
              }
              Navigator.of(dialogContext).pop();
            },
          ),
        ],
      ),
    );
  }

  Future<void> _showCategorySelectionDialog(
    BuildContext context,
    BusinessSnapshotReportState state,
  ) async {
    // We need to get categories from the bloc or from another source
    // For now, let's get unique categories from products
    final availableCategories = <int, String>{};
    for (final product in state.products) {
      if (product.categoryId != null && product.categoryName != null) {
        availableCategories[product.categoryId!] = product.categoryName!;
      }
    }

    // Remove already selected categories
    final filteredCategories = Map.fromEntries(availableCategories.entries.where((entry) =>
        !state.queryData.selectedCategories.any((selected) => selected.id == entry.key)));

    if (filteredCategories.isEmpty) {
      showNotification(
        title: 'No Categories Available',
        message: 'All categories are already selected or no categories exist.',
        severity: InfoBarSeverity.info,
      );
      return;
    }

    (int, String)? selectedCategory;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => ContentDialog(
        title: const Text('Select Category'),
        content: StatefulBuilder(builder: (context, setState) {
          return ComboBox<(int, String)>(
            placeholder: const Text('Choose a category...'),
            value: selectedCategory,
            onChanged: (value) => setState(() => selectedCategory = value),
            items: [
              for (final MapEntry(key: key, value: value) in filteredCategories.entries)
                ComboBoxItem(
                  value: (key, value),
                  child: Text(value),
                ),
            ],
          );
        }),
        actions: [
          Button(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(dialogContext).pop(),
          ),
          FilledButton(
            child: const Text('Add'),
            onPressed: () {
              if (selectedCategory != null) {
                // Create a Category object from the selected entry
                final (id, name) = selectedCategory!;
                final category = Category(id: id, name: name);

                context
                    .read<BusinessSnapshotReportBloc>()
                    .add(BusinessSnapshotReportAddSelectedCategoryEvent(category));
              }
              Navigator.of(dialogContext).pop();
            },
          ),
        ],
      ),
    );
  }

  Future<void> _generatePdfReport(
    BuildContext context,
    BusinessSnapshotReportState state,
  ) async {
    context
        .read<BusinessSnapshotReportBloc>()
        .add(const BusinessSnapshotReportSetGeneratingEvent(true));

    try {
      final image = await () {
        final context = _chartKey.currentContext;
        if (context == null) return null;

        final renderObject = context.findRenderObject();
        if (renderObject == null) return null;

        return (renderObject as RenderRepaintBoundary)
            .toImage(pixelRatio: MediaQuery.of(context).devicePixelRatio)
            .then((img) => img.toByteData(format: ImageByteFormat.png))
            .then((value) => value!.buffer.asUint8List());
      }();
      showPdfOverlay(builder: (context, overlay) {
        return PdfOverlay(
          overlayEntry: overlay,
          generatorCreator: () => _PdfGenerator(state, image),
        );
      });
    } catch (e) {
      showNotification(
        title: 'Error',
        message: 'Failed to generate PDF report: $e',
        severity: InfoBarSeverity.error,
      );
    } finally {
      if (context.mounted) {
        context
            .read<BusinessSnapshotReportBloc>()
            .add(const BusinessSnapshotReportSetGeneratingEvent(false));
      }
    }
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          icon: const Icon(FluentIcons.back),
          onPressed: () => context.navigate(AppRoutes.admin.reports),
        ),
        Spacing.h16,
        const DisplayText('Business Snapshot Report'),
      ],
    );
  }
}

const _cellPadding = pw.EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0);

class _PdfGenerator with PdfCommons implements PdfGenerator {
  const _PdfGenerator(this.state, this.chartImage);

  final BusinessSnapshotReportState state;
  final Uint8List? chartImage;

  @override
  String get fileName =>
      'business_snapshot_report_${DateFormat('yyyy_MM_dd').format(DateTime.now())}.pdf';

  @override
  Future<Uint8List> generatePdf(PdfPageFormat? format) async {
    final pdf = pw.Document();
    final logo = await rootBundle.load('assets/icons/logo.png');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: format ?? PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(12),
        header: (context) => buildPdfHeaderDoubleDate(
          context,
          logo,
          state.queryData.currentPeriodStart,
          state.queryData.currentPeriodEnd,
          reportType: 'Business Snapshot Report',
        ),
        build: (pw.Context context) {
          return [
            _buildPdfSummary(),
            pw.SizedBox(height: 8),

            // Key Metrics Section
            _buildPdfSectionHeader('Key Business Metrics'),
            pw.SizedBox(height: 4),
            _buildPdfMetricsTable(state),
            pw.SizedBox(height: 8),

            // Top Products Section
            _buildPdfSectionHeader('Top Performing Products'),
            pw.SizedBox(height: 4),
            _buildPdfTopProductsTable(state),
            pw.SizedBox(height: 8),

            // Expense Breakdown Section
            _buildPdfSectionHeader('Expense Breakdown'),
            pw.SizedBox(height: 4),
            _buildPdfExpenseBreakdownTable(state),

            if (chartImage case final chartImage?) ...[
              pw.SizedBox(height: 8),
              _buildPdfSectionHeader('Sales History Chart'),
              pw.SizedBox(height: 4),
              _buildPdfChart(chartImage),
            ],
          ];
        },
      ),
    );

    return pdf.save();
  }

  pw.Widget _buildPdfSummary() {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Report Summary',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Row(
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Report Period:',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
                    ),
                    pw.Text(
                      '${DateFormat('MMM d, yyyy').format(state.queryData.currentPeriodStart)} to ${DateFormat('MMM d, yyyy').format(state.queryData.currentPeriodEnd)}',
                      style: const pw.TextStyle(fontSize: 8),
                    ),
                  ],
                ),
              ),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Comparison Period:',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
                    ),
                    pw.Text(
                      state.queryData.comparisonPeriod.name,
                      style: const pw.TextStyle(fontSize: 8),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (state.queryData.selectedProducts.isNotEmpty ||
              state.queryData.selectedCategories.isNotEmpty) ...[
            pw.SizedBox(height: 4),
            pw.Text(
              'Filters Applied:',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
            ),
            pw.SizedBox(height: 2),
            if (state.queryData.selectedProducts.isNotEmpty)
              pw.Text(
                'Products: ${state.queryData.selectedProducts.map((p) => p.name).join(", ")}',
                style: const pw.TextStyle(fontSize: 8),
              ),
            if (state.queryData.selectedCategories.isNotEmpty)
              pw.Text(
                'Categories: ${state.queryData.selectedCategories.map((c) => c.name).join(", ")}',
                style: const pw.TextStyle(fontSize: 8),
              ),
          ],
        ],
      ),
    );
  }

  pw.Widget _buildPdfSectionHeader(String title) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey400, width: 1)),
      ),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: 11,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }

  pw.Widget _buildPdfChart(Uint8List chartImage) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      padding: const pw.EdgeInsets.all(8),
      child: pw.Column(
        children: [
          pw.Text(
            'Sales History Trend Analysis',
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Container(
            height: 200,
            width: double.infinity,
            child: pw.Image(
              pw.MemoryImage(chartImage),
              fit: pw.BoxFit.contain,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'Chart shows revenue, expenses, profit trends, and selected product/category performance over time.',
            style: const pw.TextStyle(
              fontSize: 8,
            ),
            textAlign: pw.TextAlign.center,
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPdfMetricsTable(BusinessSnapshotReportState state) {
    final metrics = state.queryData.keyMetrics ?? [];

    if (metrics.isEmpty) {
      return _buildEmptyStateMessage('No key metrics data available');
    }

    return pw.Table(
      border: pw.TableBorder.symmetric(),
      columnWidths: const {
        0: pw.FlexColumnWidth(2.5),
        1: pw.FlexColumnWidth(1.5),
        2: pw.FlexColumnWidth(1.5),
        3: pw.FlexColumnWidth(1),
      },
      children: [
        // Header row
        _buildMetricsHeaderRow(),
        // Data rows
        ...metrics.map((metric) => _buildMetricsDataRow(metric)),
      ],
    );
  }
}

pw.TableRow _buildMetricsHeaderRow() {
  return pw.TableRow(
    decoration: const pw.BoxDecoration(
      border: pw.Border(
        bottom: pw.BorderSide(color: PdfColors.grey400, width: 0.5),
      ),
    ),
    children: [
      pw.Padding(
        padding: _cellPadding,
        child: pw.Text(
          'Metric Name',
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
        ),
      ),
      pw.Padding(
        padding: _cellPadding,
        child: pw.Text(
          'Current Value',
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
        ),
      ),
      pw.Padding(
        padding: _cellPadding,
        child: pw.Text(
          'Previous Value',
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
        ),
      ),
      pw.Padding(
        padding: _cellPadding,
        child: pw.Text(
          'Change',
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
        ),
      ),
    ],
  );
}

pw.TableRow _buildMetricsDataRow(BusinessMetric metric) {
  return pw.TableRow(
    children: [
      pw.Padding(
        padding: _cellPadding,
        child: pw.Text(
          metric.name,
          style: const pw.TextStyle(fontSize: 8),
        ),
      ),
      pw.Padding(
        padding: _cellPadding,
        child: pw.Text(
          CurrencyFormatter.full(metric.currentValue),
          style: const pw.TextStyle(fontSize: 8),
        ),
      ),
      pw.Padding(
        padding: _cellPadding,
        child: pw.Text(
          CurrencyFormatter.full(metric.previousValue),
          style: const pw.TextStyle(fontSize: 8),
        ),
      ),
      pw.Padding(
        padding: _cellPadding,
        child: pw.Text(
          '${metric.percentageChange >= 0 ? "+" : ""}${metric.percentageChange.toStringAsFixed(1)}%',
          style: const pw.TextStyle(fontSize: 8),
        ),
      ),
    ],
  );
}

pw.Widget _buildPdfTopProductsTable(BusinessSnapshotReportState state) {
  final products = state.queryData.topSellingProducts ?? [];

  if (products.isEmpty) {
    return _buildEmptyStateMessage('No top products data available');
  }

  return pw.Table(
    border: pw.TableBorder.symmetric(),
    columnWidths: const {
      0: pw.FlexColumnWidth(2.5),
      1: pw.FlexColumnWidth(1),
      2: pw.FlexColumnWidth(1.5),
      3: pw.FlexColumnWidth(1.5),
    },
    children: [
      // Header row
      _buildProductsHeaderRow(),
      // Data rows
      ...products.map((product) => _buildProductsDataRow(product)),
    ],
  );
}

pw.TableRow _buildProductsHeaderRow() {
  return pw.TableRow(
    decoration: const pw.BoxDecoration(
      border: pw.Border(
        bottom: pw.BorderSide(color: PdfColors.grey400, width: 0.5),
      ),
    ),
    children: [
      pw.Padding(
        padding: _cellPadding,
        child: pw.Text(
          'Product Name',
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
        ),
      ),
      pw.Padding(
        padding: _cellPadding,
        child: pw.Text(
          'Qty Sold',
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
        ),
      ),
      pw.Padding(
        padding: _cellPadding,
        child: pw.Text(
          'Revenue',
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
        ),
      ),
      pw.Padding(
        padding: _cellPadding,
        child: pw.Text(
          'Profit',
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
        ),
      ),
    ],
  );
}

pw.TableRow _buildProductsDataRow(TopSellingProduct product) {
  return pw.TableRow(
    children: [
      pw.Padding(
        padding: _cellPadding,
        child: pw.Text(
          product.product.name,
          style: const pw.TextStyle(fontSize: 8),
        ),
      ),
      pw.Padding(
        padding: _cellPadding,
        child: pw.Text(
          product.quantitySold.toStringAsFixed(0),
          style: const pw.TextStyle(fontSize: 8),
        ),
      ),
      pw.Padding(
        padding: _cellPadding,
        child: pw.Text(
          CurrencyFormatter.full(product.revenue),
          style: const pw.TextStyle(fontSize: 8),
        ),
      ),
      pw.Padding(
        padding: _cellPadding,
        child: pw.Text(
          CurrencyFormatter.full(product.profit),
          style: const pw.TextStyle(fontSize: 8),
        ),
      ),
    ],
  );
}

pw.Widget _buildPdfExpenseBreakdownTable(BusinessSnapshotReportState state) {
  final expenses = state.queryData.expenseBreakdown ?? [];

  if (expenses.isEmpty) {
    return _buildEmptyStateMessage('No expense breakdown data available');
  }

  final totalExpenses = expenses.fold<double>(0, (sum, expense) => sum + expense.amount);

  return pw.Table(
    border: pw.TableBorder.symmetric(),
    columnWidths: const {
      0: pw.FlexColumnWidth(2.5),
      1: pw.FlexColumnWidth(1.5),
      2: pw.FlexColumnWidth(1),
    },
    children: [
      // Header row
      _buildExpenseHeaderRow(),
      // Data rows
      ...expenses.map((expense) => _buildExpenseDataRow(expense)),
      // Total row
      _buildExpenseTotalRow(totalExpenses, expenses),
    ],
  );
}

pw.TableRow _buildExpenseHeaderRow() {
  return pw.TableRow(
    decoration: const pw.BoxDecoration(
      border: pw.Border(
        bottom: pw.BorderSide(color: PdfColors.grey400, width: 0.5),
      ),
    ),
    children: [
      pw.Padding(
        padding: _cellPadding,
        child: pw.Text(
          'Expense Type',
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
        ),
      ),
      pw.Padding(
        padding: _cellPadding,
        child: pw.Text(
          'Amount',
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
        ),
      ),
      pw.Padding(
        padding: _cellPadding,
        child: pw.Text(
          'Percentage',
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
        ),
      ),
    ],
  );
}

pw.TableRow _buildExpenseDataRow(ExpenseBreakdown expense) {
  return pw.TableRow(
    children: [
      pw.Padding(
        padding: _cellPadding,
        child: pw.Text(
          expense.expenseType.name,
          style: const pw.TextStyle(fontSize: 8),
        ),
      ),
      pw.Padding(
        padding: _cellPadding,
        child: pw.Text(
          CurrencyFormatter.full(expense.amount),
          style: const pw.TextStyle(fontSize: 8),
        ),
      ),
      pw.Padding(
        padding: _cellPadding,
        child: pw.Text(
          '${expense.percentage.toStringAsFixed(1)}%',
          style: const pw.TextStyle(fontSize: 8),
        ),
      ),
    ],
  );
}

pw.TableRow _buildExpenseTotalRow(double totalExpenses, List<ExpenseBreakdown> expenses) {
  // Calculate the actual total percentage for verification
  final totalPercentage = expenses.map((e) => e.percentage).sum();

  return pw.TableRow(
    decoration: const pw.BoxDecoration(
      border: pw.Border(
        top: pw.BorderSide(color: PdfColors.grey400, width: 0.5),
      ),
    ),
    children: [
      pw.Padding(
        padding: _cellPadding,
        child: pw.Text(
          'Total',
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
        ),
      ),
      pw.Padding(
        padding: _cellPadding,
        child: pw.Text(
          CurrencyFormatter.full(totalExpenses),
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
        ),
      ),
      pw.Padding(
        padding: _cellPadding,
        child: pw.Text(
          '${totalPercentage.toStringAsFixed(1)}%',
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
        ),
      ),
    ],
  );
}

pw.Widget _buildEmptyStateMessage(String message) {
  return pw.Container(
    padding: const pw.EdgeInsets.all(16),
    decoration: pw.BoxDecoration(
      border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
      borderRadius: pw.BorderRadius.circular(4),
    ),
    child: pw.Center(
      child: pw.Text(
        message,
        style: const pw.TextStyle(
          fontSize: 10,
        ),
        textAlign: pw.TextAlign.center,
      ),
    ),
  );
}

class _SalesHistoryChart extends StatelessWidget {
  const _SalesHistoryChart({
    required this.revenueTrends,
    required this.queryData,
  });

  final List<RevenueTrend> revenueTrends;
  final BusinessSnapshotQueryData queryData;

  @override
  Widget build(BuildContext context) {
    if (revenueTrends.isEmpty) {
      return const Center(
        child: Text('No data available'),
      );
    }

    final lineChartData = _createLineChartData();

    return LineChart(lineChartData);
  }

  LineChartData _createLineChartData() {
    final lineBarsData = <LineChartBarData>[];
    final allValues = <double>[];
    final dateLabels = <String>[];

    // Add base revenue, expense, and profit lines
    if (revenueTrends.isNotEmpty) {
      final revenueSpots = <FlSpot>[];
      final expenseSpots = <FlSpot>[];
      final profitSpots = <FlSpot>[];

      for (var i = 0; i < revenueTrends.length; i++) {
        final trend = revenueTrends[i];
        revenueSpots.add(FlSpot(i.toDouble(), trend.revenue));
        expenseSpots.add(FlSpot(i.toDouble(), trend.expenses));
        profitSpots.add(FlSpot(i.toDouble(), trend.profit));

        allValues.addAll([trend.revenue, trend.expenses, trend.profit.abs()]);

        if (dateLabels.length <= i) {
          dateLabels.add(DateFormat('MMM dd').format(trend.date));
        }
      }

      // Revenue line
      lineBarsData.add(LineChartBarData(
        spots: revenueSpots,
        isCurved: true,
        color: Colors.green,
        barWidth: 3,
        isStrokeCapRound: true,
        dotData: const FlDotData(show: false),
        belowBarData: BarAreaData(show: false),
      ));

      // Expenses line
      lineBarsData.add(LineChartBarData(
        spots: expenseSpots,
        isCurved: true,
        color: Colors.red,
        barWidth: 3,
        isStrokeCapRound: true,
        dotData: const FlDotData(show: false),
        belowBarData: BarAreaData(show: false),
      ));

      // Profit line
      lineBarsData.add(LineChartBarData(
        spots: profitSpots,
        isCurved: true,
        color: Colors.blue,
        barWidth: 3,
        isStrokeCapRound: true,
        dotData: const FlDotData(show: false),
        belowBarData: BarAreaData(show: false),
      ));
    } // Add product sales trend lines
    final productSeries = queryData.productSalesTrendSeries;
    final productColors = [
      const Color(0xFF9C27B0), // Purple
      const Color(0xFFFF9800), // Orange
      const Color(0xFF009688), // Teal
      const Color(0xFFE91E63), // Pink
      const Color(0xFF3F51B5), // Indigo
      const Color(0xFF795548), // Brown
      const Color(0xFFFF5722), // Deep Orange
      const Color(0xFF00BCD4), // Cyan
    ];
    for (var seriesIndex = 0; seriesIndex < productSeries.length; seriesIndex++) {
      final series = productSeries[seriesIndex];
      final spots = <FlSpot>[];

      for (var i = 0; i < series.trends.length; i++) {
        final trend = series.trends[i];
        spots.add(FlSpot(i.toDouble(), trend.revenue));
        allValues.add(trend.revenue);
      }

      if (spots.isNotEmpty) {
        lineBarsData.add(LineChartBarData(
          spots: spots,
          isCurved: true,
          color: productColors[seriesIndex % productColors.length],
          barWidth: 2,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) {
              return FlDotCirclePainter(
                radius: 3,
                color: productColors[seriesIndex % productColors.length],
                strokeWidth: 1,
                strokeColor: Colors.white,
              );
            },
          ),
          belowBarData: BarAreaData(show: false),
        ));
      }
    } // Add category sales trend lines
    final categorySeries = queryData.categorySalesTrendSeries;
    final categoryColors = [
      const Color(0x00cddc39), // Lime
      const Color(0x00ffc107), // Amber
      const Color(0x00673ab7), // Deep Purple
      const Color(0x00607d8b), // Blue Grey
      const Color(0x008bc34a), // Light Green
      const Color(0x00f44336), // Red Accent
      const Color(0x00ffeb3b), // Yellow Accent
      const Color(0x0003a9f4), // Light Blue
    ];

    for (var seriesIndex = 0; seriesIndex < categorySeries.length; seriesIndex++) {
      final series = categorySeries[seriesIndex];
      final spots = <FlSpot>[];
      for (var i = 0; i < series.trends.length; i++) {
        final trend = series.trends[i];
        spots.add(FlSpot(i.toDouble(), trend.totalRevenue));
        allValues.add(trend.totalRevenue);
      }

      if (spots.isNotEmpty) {
        lineBarsData.add(LineChartBarData(
          spots: spots,
          isCurved: true,
          color: categoryColors[seriesIndex % categoryColors.length],
          barWidth: 2,
          isStrokeCapRound: true,
          dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 3,
                  color: categoryColors[seriesIndex % categoryColors.length],
                  strokeWidth: 1,
                  strokeColor: Colors.white,
                );
              }),
          belowBarData: BarAreaData(show: false),
        ));
      }
    }

    // Handle edge cases where there's no data
    if (allValues.isEmpty) {
      return LineChartData();
    }

    final maxY = allValues.reduce((a, b) => a > b ? a : b);
    final minY = allValues.where((v) => v < 0).isNotEmpty //
        ? allValues.reduce((a, b) => a < b ? a : b)
        : 0.0;

    final dataLength = revenueTrends.isNotEmpty
        ? revenueTrends.length
        : (productSeries.isNotEmpty
            ? productSeries.first.trends.length
            : (categorySeries.isNotEmpty ? categorySeries.first.trends.length : 1));

    return LineChartData(
      gridData: const FlGridData(show: true),
      titlesData: _createTitlesData(),
      borderData: FlBorderData(
        show: true,
        border: Border(
          bottom: BorderSide(color: Colors.black.withValues(alpha: 0.2), width: 2),
          left: BorderSide(color: Colors.black.withValues(alpha: 0.2), width: 2),
          right: const BorderSide(color: Colors.transparent),
          top: const BorderSide(color: Colors.transparent),
        ),
      ),
      minX: 0,
      maxX: dataLength > 1 ? (dataLength - 1).toDouble() : 1,
      minY: minY < 0 ? minY * 1.2 : 0, // Add padding for negative values
      maxY: maxY > 0 ? maxY * 1.1 : 100, // Add 10% padding at the top, minimum 100
      lineBarsData: lineBarsData,
      lineTouchData: LineTouchData(
        enabled: true,
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (touchedSpot) => Colors.white,
          getTooltipItems: (touchedSpots) {
            return _getTooltipItems(
                touchedSpots, productSeries, categorySeries, productColors, categoryColors);
          },
        ),
      ),
    );
  }

  List<LineTooltipItem?> _getTooltipItems(
    List<LineBarSpot> touchedSpots,
    List<ProductSalesTrendSeries> productSeries,
    List<CategorySalesTrendSeries> categorySeries,
    List<Color> productColors,
    List<Color> categoryColors,
  ) {
    return touchedSpots.map((touchedSpot) {
      final index = touchedSpot.x.toInt();

      // Handle revenue trends (first 3 bars are always revenue, expenses, profit)
      if (touchedSpot.barIndex < 3 && revenueTrends.isNotEmpty) {
        if (index < 0 || index >= revenueTrends.length) {
          return null;
        }

        final trend = revenueTrends[index];
        final dateStr = DateFormat('MMM dd').format(trend.date);

        switch (touchedSpot.barIndex) {
          case 0: // Revenue
            return LineTooltipItem(
              'Revenue\n$dateStr\n${CurrencyFormatter.full(touchedSpot.y)}',
              const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
            );
          case 1: // Expenses
            return LineTooltipItem(
              'Expenses\n$dateStr\n${CurrencyFormatter.full(touchedSpot.y)}',
              const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
            );
          case 2: // Profit
            return LineTooltipItem(
              'Profit\n$dateStr\n${CurrencyFormatter.full(touchedSpot.y)}',
              const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
            );
        }
      }

      // Handle product trends
      const productBarStart = 3;
      final productBarEnd = productBarStart + productSeries.length;

      if (touchedSpot.barIndex >= productBarStart && touchedSpot.barIndex < productBarEnd) {
        final productIndex = touchedSpot.barIndex - productBarStart;
        if (productIndex < productSeries.length) {
          final series = productSeries[productIndex];
          if (index >= 0 && index < series.trends.length) {
            final trend = series.trends[index];
            final dateStr = DateFormat('MMM dd').format(trend.date);
            return LineTooltipItem(
              '${series.product.name}\n$dateStr\n${CurrencyFormatter.full(touchedSpot.y)}',
              const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
            );
          }
        }
      }

      // Handle category trends
      final categoryBarStart = productBarEnd;
      final categoryBarEnd = categoryBarStart + categorySeries.length;

      if (touchedSpot.barIndex >= categoryBarStart && touchedSpot.barIndex < categoryBarEnd) {
        final categoryIndex = touchedSpot.barIndex - categoryBarStart;
        if (categoryIndex < categorySeries.length) {
          final series = categorySeries[categoryIndex];
          if (index >= 0 && index < series.trends.length) {
            final trend = series.trends[index];
            final dateStr = DateFormat('MMM dd').format(trend.date);
            return LineTooltipItem(
              '${series.category.name}\n$dateStr\n${CurrencyFormatter.full(touchedSpot.y)}',
              const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
            );
          }
        }
      }

      return null;
    }).toList();
  }

  FlTitlesData _createTitlesData() {
    return FlTitlesData(
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 32,
          interval: _calculateInterval(),
          getTitlesWidget: (value, meta) {
            final index = value.toInt();
            if (index < 0 || index >= revenueTrends.length) {
              return const SizedBox.shrink();
            }

            final trend = revenueTrends[index];
            final dateStr = DateFormat('MMM dd').format(trend.date);

            return SideTitleWidget(
              meta: meta,
              child: Text(
                dateStr,
                style: const TextStyle(fontSize: 12),
              ),
            );
          },
        ),
      ),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 80,
          getTitlesWidget: (value, meta) {
            return SideTitleWidget(
              meta: meta,
              child: Text(
                CurrencyFormatter.compact(value),
                style: const TextStyle(fontSize: 12),
              ),
            );
          },
        ),
      ),
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    );
  }

  double _calculateInterval() {
    // Show approximately 6-8 labels on the x-axis
    const maxLabels = 8;
    if (revenueTrends.length <= maxLabels) {
      return 1.0; // Show all labels if we have few data points
    }
    return (revenueTrends.length / maxLabels).ceilToDouble();
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({
    required this.color,
    required this.label,
  });

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 3,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(1.5),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
