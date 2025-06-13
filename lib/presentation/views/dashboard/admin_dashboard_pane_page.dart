import 'dart:async';
import 'dart:math';

import 'package:easthardware_pms/domain/models/invoice.dart';
import 'package:easthardware_pms/domain/models/product.dart';
import 'package:easthardware_pms/presentation/bloc/billing/invoicelist/invoice_list_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/inventory/product_list/product_list_bloc.dart';
import 'package:easthardware_pms/presentation/widgets/animated_single_child_scroll_view.dart';
import 'package:easthardware_pms/presentation/widgets/layout/spacing.dart';
import 'package:easthardware_pms/presentation/widgets/layout_mode_provider.dart';
import 'package:easthardware_pms/presentation/widgets/text.dart';
import 'package:easthardware_pms/presentation/widgets/ui/kpi_card.dart';
import 'package:easthardware_pms/utils/boxed.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:provider/provider.dart';
import 'package:scroll_animator/scroll_animator.dart';
import 'package:two_dimensional_scrollables/two_dimensional_scrollables.dart';

class AdminDashboardPanePage extends StatelessWidget {
  const AdminDashboardPanePage({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedSingleChildScrollView(
      child: Padding(
        padding: AppPadding.panePadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const PageHeader(),
            const SummarySection(),
            const GraphsSection(),
            const RecentSales(),
            const MostUrgentProducts(),
          ].withSpacing(() => Spacing.v8),
        ),
      ),
    );
  }
}

class PageHeader extends StatelessWidget {
  const PageHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            HeadingText('Dashboard'),
            GrayText('Overview of the system'),
          ],
        ),
      ],
    );
  }
}

class SummarySection extends StatelessWidget {
  const SummarySection({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutMode.builder((context, mode) {
      const productCount = ProductCountCard();
      const saleCount = SaleCountCard();
      const totalSales = TotalSalesCard(value: "Hi");
      const totalOrders = TotalOrdersCard(value: "Hi");

      return switch (mode) {
        LayoutMode.wide => const Row(
            children: [
              productCount,
              Spacing.h8,
              saleCount,
              Spacing.h8,
              totalSales,
              Spacing.h8,
              totalOrders,
            ],
          ),
        LayoutMode.constrained => const Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(children: [productCount, Spacing.h8, saleCount]),
              Spacing.v8,
              Row(children: [totalSales, Spacing.h8, totalOrders]),
            ],
          ),
        LayoutMode.compact => const Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              productCount,
              Spacing.v8,
              saleCount,
              Spacing.v8,
              totalSales,
              Spacing.v8,
              totalOrders,
            ],
          ),
      };
    });
  }
}

class GraphsSection extends StatelessWidget {
  const GraphsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final layoutMode = context.watch<LayoutMode>();

    switch (layoutMode) {
      case LayoutMode.wide:
        return ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 400),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(flex: 3, child: SalesOverview()),
              Spacing.h8,
              Expanded(flex: 2, child: ProductActivity()),
            ],
          ),
        );
      case LayoutMode.compact || LayoutMode.constrained:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 400),
              child: const SalesOverview(),
            ),
            Spacing.v8,
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 400),
              child: const ProductActivity(),
            ),
          ],
        );
    }
  }
}

class SalesOverview extends StatefulWidget {
  const SalesOverview({super.key});

  @override
  State<SalesOverview> createState() => _SalesOverviewState();
}

class _SalesOverviewState extends State<SalesOverview> {
  late InvoiceListState? _invoices;
  late BarChartData? _barChartData;

  @override
  void initState() {
    super.initState();

    _invoices = null;
    _barChartData = null;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final invoices = context.watch<InvoiceListBloc>().state;
    if (_invoices != invoices) {
      _invoices = invoices;

      unawaited(() async {
        final data = await _createBarChartData(invoices);
        if (!mounted) return;
        setState(() => _barChartData = data);
      }());
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DisplayText('Sales Overview'),
                    GrayText('Sales overview for the last 7 days')
                  ],
                ),
                Text("Hi"),
              ],
            ),
            Spacing.v32,
            if (_barChartData == null)
              const RecentSalesPlaceholder()
            else
              Expanded(child: BarChart(_barChartData!)),
          ],
        ),
      ),
    );
  }

  Future<BarChartData> _createBarChartData(InvoiceListState invoices) async {
    final barTouchData = BarTouchData(
      handleBuiltInTouches: true,
      touchTooltipData: BarTouchTooltipData(
        getTooltipColor: (touchedSpot) => Colors.grey[20],
      ),
    );

    final borderData = FlBorderData(
      show: true,
      border: Border(
        bottom: BorderSide(color: Colors.black.withValues(alpha: 0.2), width: 4.0),
        left: const BorderSide(color: Colors.transparent),
        right: const BorderSide(color: Colors.transparent),
        top: const BorderSide(color: Colors.transparent),
      ),
    );

    final today = DateTime.now().copyWith(
      hour: 0,
      minute: 0,
      second: 0,
      millisecond: 0,
      microsecond: 0,
    );

    final lastWeek = today.subtract(const Duration(days: 6));
    final invoicesByDay = <DateTime, List<Invoice>>{};
    final invoicesWithinTheWeek = invoices.allInvoices //
        .where((i) => i.invoiceDate.isAfter(lastWeek));

    for (var i = 0; i < 7; ++i) {
      final date = today.subtract(Duration(days: 6 - i));
      invoicesByDay[date] = <Invoice>[];
    }

    for (final invoice in invoicesWithinTheWeek) {
      final date = invoice.invoiceDate.copyWith(hour: 0, minute: 0, second: 0, millisecond: 0);

      if (!invoicesByDay.containsKey(date)) {
        printBoxed(
          "Tried to add an invoice for a date that is not in the last 7 days: $date\n${invoicesByDay.entries.join('\n')}",
          "Invoice Date Error",
        );
      }
      invoicesByDay[date]!.add(invoice);
    }

    assert(
      invoicesByDay.length <= 7,
      "There should be at most 7 days of invoices in the last week!",
    );

    final barGroups = [
      for (final (index, invoices) in invoicesByDay.values.indexed)
        () {
          final maximum = invoices.map((i) => i.amountDue).fold(0.0, (a, b) => a + b);

          return BarChartGroupData(
            x: index,
            barsSpace: 4,
            barRods: [
              BarChartRodData(
                toY: maximum,
                rodStackItems: [
                  BarChartRodStackItem(0, maximum, Colors.red),
                ],
                borderRadius: BorderRadius.zero,
                width: 12,
              ),
            ],
          );
        }(),
    ];

    final maxY = barGroups.expand((d) => d.barRods.map((s) => s.toY)).reduce(max);

    /// titlesData displays the labels around the graph.
    final titlesData = FlTitlesData(
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 96,
          minIncluded: false,
          maxIncluded: false,
          interval: 1,
          getTitlesWidget: (double value, TitleMeta meta) {
            const style = TextStyle(
              fontSize: 16,
            );

            assert(
              value == value.floorToDouble(),
              "Bottom title values should be integer-like.",
            );

            final index = value.toInt();
            assert(
              0 <= index && index < 7,
              "The value given should be a valid index for the product list!",
            );
            final weekday = invoicesByDay.keys.elementAt(index).weekday;
            assert(
              1 <= weekday && weekday <= 7,
              "The day should be between 1 and 7, but got $weekday",
            );
            const daysOfWeek = ["", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];

            return SideTitleWidget(
              meta: meta,
              child: Text(
                daysOfWeek[weekday],
                style: style,
              ),
            );
          },
        ),
      ),
      leftTitles: const AxisTitles(
        sideTitles: SideTitles(showTitles: false),
      ),
      topTitles: const AxisTitles(
        sideTitles: SideTitles(showTitles: false),
      ),
      rightTitles: AxisTitles(
        sideTitles: SideTitles(
          maxIncluded: false,
          getTitlesWidget: (double value, TitleMeta meta) {
            const style = TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            );

            return SideTitleWidget(
              meta: meta,
              child: Text(
                '${value ~/ 1}',
                style: style,
                textAlign: TextAlign.center,
              ),
            );
          },
          showTitles: true,
          interval: maxY > 0 ? (maxY ~/ 4).toDouble() : 1,
          reservedSize: 72,
        ),
      ),
    );

    return BarChartData(
      barTouchData: barTouchData,
      gridData: const FlGridData(show: true),
      titlesData: titlesData,
      borderData: borderData,
      barGroups: barGroups,
      minY: 0,
      maxY: maxY + (maxY ~/ 4).toDouble(),
    );
  }
}

class ProductActivity extends StatefulWidget {
  const ProductActivity({super.key});

  @override
  State<ProductActivity> createState() => _ProductActivityState();
}

class _ProductActivityState extends State<ProductActivity> {
  late final List<String> products = [
    for (int i = 0; i < 5; ++i) "Product ${String.fromCharCode(64 + i + 1)}"
  ];
  late InvoiceListState? _invoices;

  @override
  void initState() {
    super.initState();

    _invoices = null;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final invoices = context.watch<InvoiceListBloc>().state;
    if (_invoices != invoices) {
      _invoices = invoices;
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const DisplayText('Top Product Activity'),

                /// An example button to update the state of the product.
                Button(
                  child: const Text("Add product"),
                  onPressed: () {
                    setState(() {
                      products.add("Product ${String.fromCharCode(64 + products.length + 1)}");
                    });
                  },
                ),
              ],
            ),
            Spacing.v16,
            Expanded(child: BarChart(_createBarChartData(_invoices!))),
          ],
        ),
      ),
    );
  }

  BarChartData _createBarChartData(InvoiceListState invoices) {
    /// [lineTouchData] configures the widgets shown as the mouse hovers over points
    ///   in the data.
    final barTouchData = BarTouchData(
      handleBuiltInTouches: true,
      touchTooltipData: BarTouchTooltipData(
        getTooltipColor: (touchedSpot) => Colors.grey[20],
      ),
    );

    final borderData = FlBorderData(
      show: true,
      border: Border(
        bottom: BorderSide(color: Colors.black.withValues(alpha: 0.2), width: 4.0),
        left: const BorderSide(color: Colors.transparent),
        right: const BorderSide(color: Colors.transparent),
        top: const BorderSide(color: Colors.transparent),
      ),
    );

    final barGroups = [
      for (final (index, _) in products.indexed)
        () {
          final maximum = Random().nextInt(30).toDouble();

          return BarChartGroupData(
            x: index,
            barsSpace: 4,
            barRods: [
              BarChartRodData(
                toY: maximum,
                rodStackItems: [
                  BarChartRodStackItem(0, maximum, Colors.red),
                ],
                borderRadius: BorderRadius.zero,
                width: 12,
              ),
            ],
          );
        }(),
    ];

    final maxY = barGroups.expand((d) => d.barRods.map((s) => s.toY)).reduce(max);

    /// titlesData displays the labels around the graph.
    final titlesData = FlTitlesData(
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 96,
          minIncluded: false,
          maxIncluded: false,
          interval: 1,
          getTitlesWidget: (double value, TitleMeta meta) {
            const style = TextStyle(
              fontSize: 16,
            );

            assert(
              value == value.floorToDouble(),
              "Bottom title values should be integer-like.",
            );

            final index = value.toInt();
            assert(
              0 <= index && index < products.length,
              "The value given should be a valid index for the product list!",
            );

            return SideTitleWidget(
              meta: meta,
              child: Text(
                products[index],
                style: style,
              ),
            );
          },
        ),
      ),
      leftTitles: const AxisTitles(
        sideTitles: SideTitles(showTitles: false),
      ),
      topTitles: const AxisTitles(
        sideTitles: SideTitles(showTitles: false),
      ),
      rightTitles: AxisTitles(
        sideTitles: SideTitles(
          maxIncluded: false,
          getTitlesWidget: (double value, TitleMeta meta) {
            const style = TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            );

            return SideTitleWidget(
              meta: meta,
              child: Text(
                '${value ~/ 1}',
                style: style,
                textAlign: TextAlign.center,
              ),
            );
          },
          showTitles: true,
          interval: (maxY ~/ 4).toDouble(),
          reservedSize: 72,
        ),
      ),
    );

    return BarChartData(
      barTouchData: barTouchData,
      gridData: const FlGridData(show: true),
      titlesData: titlesData,
      borderData: borderData,
      barGroups: barGroups,
      minY: 0,
      maxY: maxY + (maxY ~/ 4).toDouble(),
      rotationQuarterTurns: 1,
    );
  }
}

class RecentSales extends StatelessWidget {
  const RecentSales({super.key});

  @override
  Widget build(BuildContext context) {
    final invoices = context.select((InvoiceListBloc b) => b.state.allInvoices);

    return ColoredBox(
      color: FluentTheme.of(context).cardColor,
      child: Padding(
        padding: AppPadding.cardPadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const DisplayText('Latest Sales'),
            Spacing.v16,
            if (invoices.isNotEmpty)
              const RecentSalesTable() //
            else
              const RecentSalesPlaceholder()
          ],
        ),
      ),
    );
  }
}

class RecentSalesPlaceholder extends StatelessWidget {
  const RecentSalesPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(FluentIcons.report_alert, size: 42.0),
          SubheadingText("No recent sales."),
          Spacing.v8,
          GrayText("Please add some sales to view them here."),
        ],
      ),
    );
  }
}

class RecentSalesTable extends StatefulWidget {
  const RecentSalesTable({super.key});

  @override
  State<RecentSalesTable> createState() => _RecentSalesTableState();
}

class _RecentSalesTableState extends State<RecentSalesTable> {
  late final AnimatedScrollController verticalScrollController;
  late final AnimatedScrollController horizontalScrollController;

  static const double cellHeight = 48.0;
  static final Map<String, (SpanExtent, Widget Function(Invoice))> _rowExtents = {
    // Order ID	Customer	Status	Total	Date
    "ID": (const FixedSpanExtent(60), (i) => Text(i.id.toString())),
    "Customer Name": (
      const MaxSpanExtent(
        FixedSpanExtent(240.00),
        FractionalSpanExtent(0.33),
      ),
      (i) => Text(i.customerName),
    ),
    "Total": (const FixedSpanExtent(120), (i) => Text(i.amountDue.toString())),
    "Payment Method": (
      const MaxSpanExtent(
        FixedSpanExtent(120.00),
        FractionalSpanExtent(0.33),
      ),
      (i) => Text({0: "Cash", 1: "GCash"}[i.paymentMethod] ?? "Unknown"),
    ),
    "Date": (const FixedSpanExtent(120), (i) => Text(i.invoiceDate.toString())),
  };

  @override
  void initState() {
    super.initState();
    verticalScrollController = AnimatedScrollController(
      animationFactory: const ChromiumEaseInOut(),
    );
    horizontalScrollController = AnimatedScrollController(
      animationFactory: const ChromiumEaseInOut(),
    );
  }

  @override
  void dispose() {
    verticalScrollController.dispose();
    horizontalScrollController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final invoices = context.select((InvoiceListBloc b) => b.state.allInvoices);
    final matrix = [
      [
        for (final columnName in _rowExtents.keys)
          Text(columnName, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
      for (final invoice in invoices) //
        [for (final (_, selector) in _rowExtents.values) selector(invoice)]
    ];

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: cellHeight * min(1 + 8, matrix.length)),
      child: TableView.builder(
        verticalDetails: ScrollableDetails.vertical(
          controller: verticalScrollController,
        ),
        horizontalDetails: ScrollableDetails.horizontal(
          controller: horizontalScrollController,
        ),
        rowCount: matrix.length,
        columnCount: matrix.first.length,
        pinnedRowCount: 1,
        columnBuilder: (int index) => TableSpan(extent: _rowExtents.values.elementAt(index).$1),
        rowBuilder: (int index) => const TableSpan(extent: FixedSpanExtent(cellHeight)),
        cellBuilder: (BuildContext context, TableVicinity vicinity) {
          final (y, x) = (vicinity.row, vicinity.column);

          return TableViewCell(
            child: Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: matrix[y][x],
            ),
          );
        },
      ),
    );
  }
}

class MostUrgentProducts extends StatefulWidget {
  const MostUrgentProducts({super.key});

  @override
  State<MostUrgentProducts> createState() => _MostUrgentProductsState();
}

class _MostUrgentProductsState extends State<MostUrgentProducts> {
  late final AnimatedScrollController verticalScrollController;
  late final AnimatedScrollController horizontalScrollController;

  static const double cellHeight = 48.0;
  static final Map<String, (SpanExtent, Widget Function(Product))> _rowExtents = {
    "ID": (const FixedSpanExtent(60), (p) => Text(p.id.toString())),
    "Name": (
      const MaxSpanExtent(
        FixedSpanExtent(240.00),
        FractionalSpanExtent(0.33),
      ),
      (p) => Text(p.name),
    ),
    "Category": (
      const MaxSpanExtent(
        FixedSpanExtent(80.00),
        FractionalSpanExtent(0.33),
      ),
      (p) => Text(p.categoryName ?? ""),
    ),
    "Price": (const FixedSpanExtent(120), (p) => Text(p.salePrice.toString())),
    "Cost": (const FixedSpanExtent(120), (p) => Text(p.orderCost.toString())),
    "Quantity": (const FixedSpanExtent(120), (p) => Text(p.quantity.toString())),
    "Actions": (
      const MaxSpanExtent(
        FixedSpanExtent(80.00),
        RemainingSpanExtent(),
      ),
      (p) => const Text("Edit"),
    ),
  };

  @override
  void initState() {
    super.initState();
    verticalScrollController = AnimatedScrollController(
      animationFactory: const ChromiumEaseInOut(),
    );
    horizontalScrollController = AnimatedScrollController(
      animationFactory: const ChromiumEaseInOut(),
    );
  }

  @override
  void dispose() {
    verticalScrollController.dispose();
    horizontalScrollController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final products = context.select((ProductListBloc b) => b.state.allProducts);
    final matrix = [
      [
        for (final columnName in _rowExtents.keys)
          Text(columnName, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
      for (final product in products) //
        [for (final (_, selector) in _rowExtents.values) selector(product)]
    ];

    return ColoredBox(
      color: FluentTheme.of(context).cardColor,
      child: Padding(
        padding: AppPadding.cardPadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const DisplayText('Lower Stocked Products'),
            Spacing.v16,
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: cellHeight * min(1 + 8, matrix.length)),
              child: TableView.builder(
                verticalDetails: ScrollableDetails.vertical(
                  controller: verticalScrollController,
                ),
                horizontalDetails: ScrollableDetails.horizontal(
                  controller: horizontalScrollController,
                ),
                rowCount: matrix.length,
                columnCount: matrix.first.length,
                pinnedRowCount: 1,
                columnBuilder: (int index) => TableSpan(
                  extent: _rowExtents.values.elementAt(index).$1,
                ),
                rowBuilder: (int index) => const TableSpan(extent: FixedSpanExtent(cellHeight)),
                cellBuilder: (BuildContext context, TableVicinity vicinity) {
                  final (y, x) = (vicinity.row, vicinity.column);

                  return TableViewCell(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: matrix[y][x],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProductCountCard extends StatelessWidget {
  const ProductCountCard({super.key});

  @override
  Widget build(BuildContext context) {
    final productCount = context.select((ProductListBloc b) => b.state.allProducts.length);

    return KPICard(
      'Product Count',
      value: productCount.toString(),
      icon: const Icon(FluentIcons.product),
    );
  }
}

class SaleCountCard extends StatelessWidget {
  const SaleCountCard({super.key});

  @override
  Widget build(BuildContext context) {
    final products = context.select((ProductListBloc b) => b.state.allProducts);
    final lowStockProducts = products.where((p) => p.quantity < p.deadStockThreshold).length;

    return KPICard(
      'Low Stock Products',
      value: lowStockProducts.toString(),
      icon: const Icon(FluentIcons.product),
    );
  }
}

class TotalSalesCard extends KPICard {
  const TotalSalesCard({super.key, required super.value})
      : super(
          'Total Sales',
          icon: const Icon(FluentIcons.product_warning),
        );
}

class TotalOrdersCard extends KPICard {
  const TotalOrdersCard({super.key, required super.value})
      : super(
          'Total Orders',
          icon: const Icon(FluentIcons.market_down),
        );
}
