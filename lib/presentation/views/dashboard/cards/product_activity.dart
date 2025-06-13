import 'dart:async';
import 'dart:math';

import 'package:easthardware_pms/domain/models/invoice.dart';
import 'package:easthardware_pms/domain/repository/invoice_product_repository.dart';
import 'package:easthardware_pms/presentation/bloc/billing/invoicelist/invoice_list_bloc.dart';
import 'package:easthardware_pms/presentation/views/dashboard/cards/recent_sales.dart';
import 'package:easthardware_pms/presentation/widgets/layout/spacing.dart';
import 'package:easthardware_pms/presentation/widgets/text.dart';
import 'package:easthardware_pms/utils/boxed.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:provider/provider.dart';

class ProductActivity extends StatefulWidget {
  const ProductActivity({super.key});

  @override
  State<ProductActivity> createState() => _ProductActivityState();
}

class _ProductActivityState extends State<ProductActivity> {
  static const int productDisplayLimit = 6;

  late InvoiceListState? _invoices;
  late BarChartData? _barChartData;
  late void Function()? _requestCanceller;

  @override
  void initState() {
    super.initState();

    _invoices = null;
    _barChartData = null;
    _requestCanceller = null;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final invoices = context.watch<InvoiceListBloc>().state;
    if (_invoices != invoices) {
      _requestCanceller?.call();
      var isCancelled = false;

      _invoices = invoices;
      _requestCanceller = () => isCancelled = true;
      unawaited(() async {
        final data = await _createBarChartData(invoices.allInvoices);
        if (!mounted || isCancelled) return;
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
      color: FluentTheme.of(context).cardColor,
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
                  onPressed: () {},
                ),
              ],
            ),
            Spacing.v16,
            if (_barChartData case final barChartData?)
              Expanded(child: BarChart(barChartData))
            else
              const RecentSalesPlaceholder(),
          ],
        ),
      ),
    );
  }

  Future<BarChartData> _createBarChartData(List<Invoice> invoices) async {
    /// This map counts the occurrences of each product in the last 30 days.
    ///   The key is a tuple of (productId, productName), and the value is the count.
    final productOccurrences = <(int, String), int>{};

    /// Get the invoice product repository from the context.
    final invoiceProductRepository = context.read<InvoiceProductRepository>();

    /// Filter the invoices to only include those created in the last 30 days,
    ///   and then map each invoice to its products.
    final products = await invoices
        .where((i) => i.creationDate.isAfter(DateTime.now().subtract(const Duration(days: 30))))
        .map((i) => invoiceProductRepository.getInvoiceProductsByInvoiceId(i.id!))
        .wait;

    /// For each product in the filtered invoices,
    ///   count the occurrences of each product by its ID and name.
    for (final product in products.expand((l) => l)) {
      final productId = product!.productId;
      final name = product.productName;
      final compositeKey = (productId, name);

      productOccurrences[compositeKey] ??= 0;
      productOccurrences[compositeKey] = productOccurrences[compositeKey]! + 1;
    }

    /// Sort the occurrences by the count in descending order,
    ///   and take the top [productDisplayLimit] occurrences.
    final topProducts = productOccurrences.entries
        .toList()
        .sorted((a, b) => b.value.compareTo(a.value))
        .take(productDisplayLimit)
        .map((e) => (e.key.$2, e.value))
        .toList();

    printBoxed(
      "Product occurrences:\n${productOccurrences.entries.join('\n')}",
      "Product Activity",
    );

    /// [lineTouchData] configures the widgets shown as the mouse hovers over points
    ///   in the data.
    final barTouchData = BarTouchData(
      handleBuiltInTouches: true,
      touchTooltipData: BarTouchTooltipData(
        getTooltipColor: (touchedSpot) => Colors.grey[20],
        getTooltipItem: (group, groupIndex, rod, rodIndex) {
          final occurrences = rod.toY.toInt();

          return BarTooltipItem(
            '$occurrences sales\nfor the past 30 days.',
            const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          );
        },
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
      for (final (index, (_, occurrences)) in topProducts.indexed)
        BarChartGroupData(
          x: index,
          barsSpace: 4,
          barRods: [
            BarChartRodData(
              toY: occurrences.toDouble(),
              rodStackItems: [
                BarChartRodStackItem(0, occurrences.toDouble(), Colors.red),
              ],
              borderRadius: BorderRadius.zero,
              width: 12,
            ),
          ],
        ),
    ];

    final maxY = barGroups.expand((d) => d.barRods.map((s) => s.toY)).fold(0.0, max);

    /// titlesData displays the labels around the graph.
    final titlesData = FlTitlesData(
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 192,
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
                topProducts[index].$1,
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
          interval: maxY <= 0 ? null : (maxY ~/ 4).toDouble(),
          reservedSize: 32,
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
      maxY: maxY + (maxY / 4).toDouble(),
      rotationQuarterTurns: 1,
    );
  }
}

extension<T> on List<T> {
  List<T> sorted(int Function(T a, T b) compare) {
    final list = toList();
    list.sort(compare);
    return list;
  }
}
