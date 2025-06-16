import 'dart:async';
import 'dart:math';

import 'package:easthardware_pms/domain/models/invoice.dart';
import 'package:easthardware_pms/presentation/bloc/billing/invoicelist/invoice_list_bloc.dart';
import 'package:easthardware_pms/presentation/views/dashboard/cards/recent_sales.dart';
import 'package:easthardware_pms/presentation/widgets/layout/spacing.dart';
import 'package:easthardware_pms/presentation/widgets/text.dart';
import 'package:easthardware_pms/utils/boxed.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:provider/provider.dart';

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
      color: FluentTheme.of(context).cardColor,
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
            if (_barChartData case final barChartData?)
              Expanded(child: BarChart(barChartData))
            else
              const RecentSalesPlaceholder()
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
    final invoicesWithinTheWeek = invoices.invoices //
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
        continue;
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
          reservedSize: 32,
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
