import 'dart:async';
import 'dart:math';

import 'package:easthardware_pms/domain/models/invoice.dart';
import 'package:easthardware_pms/domain/repository/invoice_product_repository.dart';
import 'package:easthardware_pms/presentation/bloc/billing/invoicelist/invoice_list_bloc.dart';
import 'package:easthardware_pms/presentation/views/dashboard/cards/recent_sales.dart';
import 'package:easthardware_pms/presentation/widgets/layout/spacing.dart';
import 'package:easthardware_pms/presentation/widgets/text.dart';
import 'package:easthardware_pms/utils/boxed.dart';
import 'package:easthardware_pms/utils/try_future.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TopProductActivity extends StatefulWidget {
  const TopProductActivity({super.key});

  @override
  State<TopProductActivity> createState() => _TopProductActivityState();
}

enum TopProductActivityChoice {
  today,
  lastWeek,
  last30Days,
  currentMonth,
  currentYear,
  allTime;

  @override
  String toString() {
    switch (this) {
      case today:
        return "Today";
      case lastWeek:
        return "Last 7 Days";
      case last30Days:
        return "Last 30 Days";
      case currentMonth:
        return "Current Month";
      case currentYear:
        return "Current Year";
      case allTime:
        return "All Time";
    }
  }

  String get description {
    switch (this) {
      case today:
        return "today.";
      case lastWeek:
        return "last week.";
      case last30Days:
        return "last 30 days.";
      case currentMonth:
        return "this month.";
      case currentYear:
        return "this year.";
      case allTime:
        return "all time.";
    }
  }

  bool check(DateTime date) {
    switch (this) {
      case today:
        return date.isAfter(DateTime.now().subtract(const Duration(days: 1)));
      case lastWeek:
        return date.isAfter(DateTime.now().subtract(const Duration(days: 7)));
      case last30Days:
        return date.isAfter(DateTime.now().subtract(const Duration(days: 30)));
      case currentMonth:
        return date.month == DateTime.now().month && date.year == DateTime.now().year;
      case currentYear:
        return date.year == DateTime.now().year;
      case allTime:
        return true;
    }
  }
}

class _TopProductActivityState extends State<TopProductActivity> {
  static const int productDisplayLimit = 5;

  late final SharedPreferencesAsync _preferences = SharedPreferencesAsync();
  late final ValueNotifier<TopProductActivityChoice> _productActivityChoice;
  late List<Invoice>? _invoices;
  late BarChartData? _barChartData;
  late void Function()? _requestCanceller;

  @override
  void initState() {
    super.initState();

    _invoices = null;
    _productActivityChoice = ValueNotifier(TopProductActivityChoice.last30Days) //
      ..addListener(() async {
        if (_invoices == null) return;
        _updateBarChartData(_invoices!);
        _preferences.setInt('top_product_activity_choice', _productActivityChoice.value.index);
      });
    _barChartData = null;
    _requestCanceller = null;

    _invoices = null;
    _barChartData = null;
    _requestCanceller = null;

    unawaited(() async {
      final stored = await _preferences.getInt('top_product_activity_choice');
      if (stored == null || !mounted) return;

      setState(() => _productActivityChoice.value = TopProductActivityChoice.values[stored]);
    }());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    /// If the invoices are not loaded yet, we need to trigger a fetch.
    final invoices = context.watch<InvoiceListBloc>().state.invoices;
    if (_invoices != invoices) {
      _invoices = invoices;
      _updateBarChartData(invoices);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: FluentTheme.of(context).cardColor,
      child: Padding(
        padding: AppPadding.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const DisplayText('Top Product Activity'),
                    GrayText('Top sales ${_productActivityChoice.value.description}'),
                  ],
                ),

                /// An example button to update the state of the product.
                ComboBox(
                  value: _productActivityChoice.value,
                  items: [
                    for (final choice in TopProductActivityChoice.values)
                      ComboBoxItem<TopProductActivityChoice>(
                        value: choice,
                        child: Text(choice.toString()),
                      ),
                  ],
                  onChanged: (value) {
                    if (value == null) return;

                    _productActivityChoice.value = value;
                  },
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

  void _updateBarChartData(List<Invoice> invoices) {
    _requestCanceller?.call();
    var isCancelled = false;

    _requestCanceller = () => isCancelled = true;
    unawaited(() async {
      final data = await _createBarChartData(invoices);
      if (!mounted || isCancelled) return;

      setState(() => _barChartData = data);
    }());
  }

  Future<BarChartData> _createBarChartData(List<Invoice> invoices) async {
    /// This map counts the occurrences of each product in the last 30 days.
    ///   The key is a tuple of (productId, productName), and the value is the count.
    final productOccurrences = <(int, String), int>{};

    /// Get the invoice product repository from the context.
    final invoiceProductRepository = context.read<InvoiceProductRepository>();

    /// Filter the invoices to only include those created in the last 30 days,
    ///   and then map each invoice to its products.
    final (products, error) = await invoices
        .where((i) => _productActivityChoice.value.check(i.creationDate))
        .map((i) => invoiceProductRepository.fetchInvoiceProductByInvoice(i.id!))
        .wait
        .tryCatch();

    if (error != null) {
      printBoxed(
        "Failed to fetch products for the last 30 days: $error",
        "ProductActivity",
      );
      throw Exception("Failed to fetch products for the last 30 days");
    }
    assert(products != null, "Products should not be null after fetching.");

    /// For each product in the filtered invoices,
    ///   count the occurrences of each product by its ID and name.
    for (final product in products!.expand((l) => l)) {
      final productId = product.productId;
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
          reservedSize: 160,
          minIncluded: false,
          maxIncluded: false,
          interval: 1,
          getTitlesWidget: (double value, TitleMeta meta) {
            assert(
              value == value.floorToDouble(),
              "Bottom title values should be integer-like.",
            );

            final index = value.toInt();
            assert(
              0 <= index && index < products.length,
              "The value given should be a valid index for the product list!",
            );

            final (message, _) = topProducts[index];

            return SideTitleWidget(
              meta: meta,
              child: Tooltip(
                message: message,
                triggerMode: TooltipTriggerMode.tap,
                child: Text(
                  message,
                  textAlign: TextAlign.right,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    decoration: TextDecoration.underline,
                  ),
                ),
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
