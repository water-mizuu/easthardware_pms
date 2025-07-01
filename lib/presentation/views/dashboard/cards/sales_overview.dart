import 'dart:async';
import 'dart:math';

import 'package:easthardware_pms/domain/models/invoice.dart';
import 'package:easthardware_pms/presentation/bloc/billing/invoicelist/invoice_list_bloc.dart';
import 'package:easthardware_pms/presentation/widgets/helper/currency_formatter.dart';
import 'package:easthardware_pms/presentation/widgets/layout/spacing.dart';
import 'package:easthardware_pms/presentation/widgets/text.dart';
import 'package:easthardware_pms/utils/boxed.dart';
import 'package:easthardware_pms/utils/date_filter.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:provider/provider.dart';

enum SalesOverviewChoice {
  thisWeek,
  last7Days,
  thisMonth,
  last30Days,
  lastMonth,
  thisYear;

  @override
  String toString() {
    switch (this) {
      case thisWeek:
        return "This Week";
      case last7Days:
        return "Last 7 Days";
      case thisMonth:
        return "This Month";
      case last30Days:
        return "Last 30 Days";
      case lastMonth:
        return "Last Month";
      case thisYear:
        return "This Year";
    }
  }

  String get description {
    switch (this) {
      case thisWeek:
        return "current week.";
      case last7Days:
        return "last 7 days.";
      case thisMonth:
        return "current month.";
      case last30Days:
        return "last 30 days.";
      case lastMonth:
        return "last month.";
      case thisYear:
        return "current year.";
    }
  }
}

class SalesOverview extends StatefulWidget {
  const SalesOverview({super.key});

  @override
  State<SalesOverview> createState() => _SalesOverviewState();
}

class _SalesOverviewState extends State<SalesOverview> {
  late final ValueNotifier<SalesOverviewChoice> _salesOverviewChoice;
  late List<Invoice>? _invoices;
  late BarChartData? _barChartData;
  late void Function()? _requestCanceller;

  @override
  void initState() {
    super.initState();

    _salesOverviewChoice = ValueNotifier(SalesOverviewChoice.last7Days)
      ..addListener(() {
        if (_invoices case final invoices?) _updateBarChartData(invoices);
      });

    _invoices = null;
    _barChartData = null;
    _requestCanceller = null;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final invoices = context.watch<InvoiceListBloc>().state.invoices;
    if (_invoices != invoices) {
      _invoices = invoices;
      _updateBarChartData(invoices);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: FluentTheme.of(context).cardColor,
      padding: AppPadding.cardPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const DisplayText('Sales Overview'),
                  ListenableBuilder(
                    listenable: _salesOverviewChoice,
                    builder: (context, _) {
                      return GrayText(
                        'Sales overview for the ${_salesOverviewChoice.value.description}',
                      );
                    },
                  )
                ],
              ),
              ListenableBuilder(
                listenable: _salesOverviewChoice,
                builder: (context, _) {
                  return ComboBox(
                    value: _salesOverviewChoice.value,
                    items: [
                      for (final choice in SalesOverviewChoice.values)
                        ComboBoxItem<SalesOverviewChoice>(
                          value: choice,
                          child: Text(choice.toString()),
                        ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;

                      _salesOverviewChoice.value = value;
                    },
                  );
                },
              ),
            ],
          ),
          Spacing.v32,
          if (_barChartData case final barChartData?)
            Expanded(child: BarChart(barChartData))
          else
            const _RecentSalesPlaceholder()
        ],
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
    final barTouchData = BarTouchData(
      handleBuiltInTouches: true,
      touchTooltipData: BarTouchTooltipData(
        getTooltipColor: (touchedSpot) => Colors.grey[10],
        getTooltipItem: (group, groupIndex, rod, rodIndex) {
          final totalAmount = rod.toY;
          final formattedAmount = CurrencyFormatter.full(totalAmount);

          return BarTooltipItem(
            formattedAmount,
            const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 14.0,
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

    final (titlesData, barGroups, maxY) = await switch (_salesOverviewChoice.value) {
      SalesOverviewChoice.last7Days => _computeLast7DaysData(invoices),
      SalesOverviewChoice.thisWeek => _computeThisWeekData(invoices),
      SalesOverviewChoice.thisMonth => _computeThisMonthData(invoices),
      SalesOverviewChoice.last30Days => _computeLast30DaysData(invoices),
      SalesOverviewChoice.lastMonth => _computeLastMonthData(invoices),
      // SalesOverviewChoice.thisQuarter => _computeThisQuarterData(invoices),
      // SalesOverviewChoice.lastQuarter => _computeLastQuarterData(invoices),
      SalesOverviewChoice.thisYear => _computeThisYearData(invoices),
    };

    return BarChartData(
      gridData: const FlGridData(show: true),
      barTouchData: barTouchData,
      borderData: borderData,
      titlesData: titlesData,
      barGroups: barGroups,
      minY: 0,
      maxY: maxY,
    );
  }
}

class _RecentSalesPlaceholder extends StatelessWidget {
  const _RecentSalesPlaceholder();

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

// Common chart utility functions to be shared across all chart types
class _ChartUtils {
  /// Creates a map of dates to empty invoice lists for daily data
  static Map<DateTime, List<Invoice>> createDailyDateMap({
    required DateTime startDate,
    required DateTime endDate,
  }) {
    final result = <DateTime, List<Invoice>>{};
    final daysBetween = endDate.difference(startDate).inDays + 1;

    for (var i = 0; i < daysBetween; ++i) {
      final date = startDate.add(Duration(days: i)).zeroedTime();
      result[date] = <Invoice>[];
    }

    return result;
  }

  /// Creates a map of month start dates to empty invoice lists
  static Map<DateTime, List<Invoice>> createMonthlyDateMap({
    required int year,
    required int startMonth,
    required int numberOfMonths,
  }) {
    final result = <DateTime, List<Invoice>>{};

    for (var i = 0; i < numberOfMonths; i++) {
      var month = startMonth + i;
      var actualYear = year;

      // Handle overflow to next year
      if (month > 12) {
        month = month % 12;
        if (month == 0) month = 12;
        actualYear += (startMonth + i - 1) ~/ 12;
      }

      final monthDate = DateTime(actualYear, month, 1);
      result[monthDate] = [];
    }

    return result;
  }

  /// Filter invoices to those falling within a date range
  static List<Invoice> filterInvoicesInDateRange(
    List<Invoice> allInvoices,
    DateTime startDate,
    DateTime endDate,
  ) {
    return allInvoices.where((inv) {
      final invDate = inv.invoiceDate;

      return invDate.isWithinTheDays(startDate, endDate);
    }).toList();
  }

  /// Group filtered invoices into the dateMap, with a specified bar limit per date
  static void groupInvoicesByDate({
    required Map<DateTime, List<Invoice>> dateMap,
    required List<Invoice> filteredInvoices,
    required int barLimit,
    required String errorPrefix,
  }) {
    for (final invoice in filteredInvoices) {
      final date = invoice.invoiceDate.zeroedTime();

      // For daily data, use the exact date
      if (dateMap.containsKey(date)) {
        _addInvoiceToDateMap(dateMap, date, invoice, barLimit);
        continue;
      }

      // For monthly data, find the month start date
      final monthKey = DateTime(date.year, date.month, 1);
      if (dateMap.containsKey(monthKey)) {
        _addInvoiceToDateMap(dateMap, monthKey, invoice, barLimit);
        continue;
      }

      // Log error if we can't place the invoice
      final start = dateMap.keys.isEmpty ? "none" : dateMap.keys.first.toIso8601String();
      final end = dateMap.keys.isEmpty ? "none" : dateMap.keys.last.toIso8601String();
      printBoxed(
        "Invoice date ${invoice.invoiceDate} (normalized: $date) not found in date map. "
            "Map covers $start to $end. Keys: ${dateMap.keys.map((d) => d.toIso8601String()).join(', ')}",
        "Invoice Date Error ($errorPrefix)",
      );
    }
  }

  /// Helper to add an invoice to a date map with a limit per date
  static void _addInvoiceToDateMap(
    Map<DateTime, List<Invoice>> dateMap,
    DateTime key,
    Invoice invoice,
    int barLimit,
  ) {
    final invoiceList = dateMap[key]!;

    // If we haven't reached the bar limit, simply add the invoice
    if (invoiceList.length < barLimit) {
      invoiceList.add(invoice);
      return;
    }

    // Otherwise, find a smaller invoice to replace
    final smallerInvoiceToReplace = invoiceList
        .where((i) => i.amountDue < invoice.amountDue)
        .fold<Invoice?>(
            null,
            (previous, current) =>
                (previous == null || current.amountDue < previous.amountDue) ? current : previous);

    if (smallerInvoiceToReplace != null) {
      invoiceList.remove(smallerInvoiceToReplace);
      invoiceList.add(invoice);
    }
  }

  /// Create BarChartGroupData based on invoice data grouped by date
  static List<BarChartGroupData> createBarGroups(
    Map<DateTime, List<Invoice>> dateMap, {
    double barWidth = 8,
    double barsSpace = 4,
    bool isMonthlyData = false,
  }) {
    return [
      for (final (index, invoicesInDay) in dateMap.values.indexed)
        BarChartGroupData(
          x: index,
          barsSpace: barsSpace,
          barRods: [
            for (final invoice in invoicesInDay)
              BarChartRodData(
                toY: invoice.amountDue,
                rodStackItems: [BarChartRodStackItem(0, invoice.amountDue, Colors.blue)],
                borderRadius: BorderRadius.zero,
                width: isMonthlyData ? 16 : barWidth,
              ),
          ],
        ),
    ];
  }

  /// For monthly data where we sum up the invoices per month
  static List<BarChartGroupData> createSummarizedMonthlyBarGroups(
    Map<DateTime, List<Invoice>> invoicesByMonth,
  ) {
    final barGroups = <BarChartGroupData>[];

    var xIndex = 0;
    for (final entry in invoicesByMonth.entries) {
      final monthlyInvoices = entry.value;
      final monthlyTotal = monthlyInvoices.fold(0.0, (sum, inv) => sum + inv.amountDue);

      barGroups.add(
        BarChartGroupData(
          x: xIndex++,
          barRods: [
            BarChartRodData(
              toY: monthlyTotal,
              rodStackItems: [BarChartRodStackItem(0, monthlyTotal, Colors.blue)],
              borderRadius: BorderRadius.zero,
              width: 16, // Wider bars for monthly data
            ),
          ],
        ),
      );
    }

    return barGroups;
  }

  /// Create chart title data with consistent styling across all chart types
  static FlTitlesData createTitlesData({
    required Map<DateTime, List<Invoice>> dateMap,
    required double maxY,
    required double interval,
    bool showMonthNames = false,
    bool showYearInLabel = false,
    required String Function(DateTime date) formatLabel,
  }) {
    return FlTitlesData(
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 24,
          interval: interval,
          getTitlesWidget: (double value, TitleMeta meta) {
            const style = TextStyle(fontSize: 14);
            final index = value.toInt();
            final intInterval = interval.toInt();

            if (index < 0 || index >= dateMap.keys.length || index % intInterval != 0) {
              return const SizedBox.shrink();
            }

            final dateKey = dateMap.keys.elementAt(index);

            return SideTitleWidget(
              meta: meta,
              space: 4,
              child: Text(formatLabel(dateKey), style: style),
            );
          },
        ),
      ),
      leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: AxisTitles(
        sideTitles: SideTitles(
          maxIncluded: false,
          getTitlesWidget: (double value, TitleMeta meta) {
            const style = TextStyle(fontWeight: FontWeight.bold, fontSize: 14);
            final formattedValue = CurrencyFormatter.compact(value);

            return SideTitleWidget(
              meta: meta,
              child: Text(
                formattedValue,
                style: style,
                textAlign: TextAlign.center,
                overflow: TextOverflow.fade,
              ),
            );
          },
          showTitles: true,
          interval: maxY > 0 ? (maxY ~/ 4).toDouble() : 1,
          reservedSize: 96,
        ),
      ),
    );
  }

  /// Calculate a maximum of labels for a date range
  static double calculateLabelInterval(int totalDates, int maxLabels) {
    return max(1.0, (totalDates / maxLabels).ceilToDouble());
  }

  /// Format date labels specifically for monthly views
  static String formatMonthLabel(DateTime date, bool includeYear) {
    const monthNames = [
      "",
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec"
    ];
    if (includeYear) {
      return "${monthNames[date.month]} ${date.year}";
    }
    return monthNames[date.month];
  }

  /// Compute the maximum Y value from bar groups and add some padding
  static double computeMaxY(List<BarChartGroupData> barGroups) {
    final maxY = barGroups.expand((d) => d.barRods.map((s) => s.toY)).fold(0.0, max);
    return maxY + (maxY ~/ 5); // Add a bit of padding at the top
  }
}

Future<(FlTitlesData, List<BarChartGroupData>, double)> _computeThisWeekData(
  List<Invoice> invoices, {
  int startOfWeekDay = DateTime.monday,
}) async {
  final today = DateTime.now().zeroedTime();
  // Adjust to make the start of the week customizable
  var daysToSubtract = today.weekday - startOfWeekDay;
  daysToSubtract %= 7; // Ensure we wrap around the week correctly
  final startOfWeek = today.subtract(Duration(days: daysToSubtract));
  final endOfWeek = startOfWeek.add(const Duration(days: 7 - 1));

  // Create date map using utility
  final invoicesByDay = _ChartUtils.createDailyDateMap(
    startDate: startOfWeek,
    endDate: endOfWeek,
  );

  // Filter invoices for date range
  final invoicesWithinRange = _ChartUtils.filterInvoicesInDateRange(
    invoices,
    startOfWeek,
    endOfWeek,
  );

  // Group invoices into dates with a bar limit
  _ChartUtils.groupInvoicesByDate(
    dateMap: invoicesByDay,
    filteredInvoices: invoicesWithinRange,
    barLimit: 3,
    errorPrefix: "This Week",
  );

  // Create bar groups
  final barGroups = _ChartUtils.createBarGroups(
    invoicesByDay,
    barWidth: 8,
    barsSpace: 4,
  );

  // Calculate maxY for the chart
  final maxY = _ChartUtils.computeMaxY(barGroups);

  // For this week, we show each day with a custom label
  const daysOfWeek = ["", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
  final titlesData = _ChartUtils.createTitlesData(
    dateMap: invoicesByDay,
    maxY: maxY,
    interval: 1, // Show all 7 days
    formatLabel: (date) => daysOfWeek[date.weekday],
  );

  return (titlesData, barGroups, maxY);
}

Future<(FlTitlesData, List<BarChartGroupData>, double)> _computeLast7DaysData(
  List<Invoice> invoices,
) async {
  final today = DateTime.now().zeroedTime();
  final startDate = today.subtract(const Duration(days: 6));

  // Create date map using utility
  final invoicesByDay = _ChartUtils.createDailyDateMap(
    startDate: startDate,
    endDate: today,
  );

  // Filter invoices for date range
  final invoicesWithinRange = _ChartUtils.filterInvoicesInDateRange(
    invoices,
    startDate,
    today,
  );

  // Group invoices into dates with a bar limit
  _ChartUtils.groupInvoicesByDate(
    dateMap: invoicesByDay,
    filteredInvoices: invoicesWithinRange,
    barLimit: 3,
    errorPrefix: "Last 7 Days",
  );

  assert(
    invoicesByDay.length <= 7,
    "There should be at most 7 days of invoices in the last week!",
  );

  // Create bar groups
  final barGroups = _ChartUtils.createBarGroups(
    invoicesByDay,
    barWidth: 8,
    barsSpace: 4,
  );

  // Calculate maxY for the chart
  final maxY = _ChartUtils.computeMaxY(barGroups);

  // For the last 7 days, we show each day with a custom label
  const daysOfWeek = ["", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
  final titlesData = _ChartUtils.createTitlesData(
    dateMap: invoicesByDay,
    maxY: maxY,
    interval: 1, // Show all 7 days
    formatLabel: (date) => daysOfWeek[date.weekday],
  );

  return (titlesData, barGroups, maxY);
}

Future<(FlTitlesData, List<BarChartGroupData>, double)> _computeThisMonthData(
  List<Invoice> invoices,
) async {
  final today = DateTime.now().zeroedTime();
  final startOfMonth = DateTime(today.year, today.month, 1);
  // The last day of the current month is the current day
  final endOfMonth = today;
  final daysInMonth = endOfMonth.day;

  // Create date map using utility
  final invoicesByDay = _ChartUtils.createDailyDateMap(
    startDate: startOfMonth,
    endDate: endOfMonth,
  );

  // Filter invoices for date range
  final invoicesWithinRange = _ChartUtils.filterInvoicesInDateRange(
    invoices,
    startOfMonth,
    endOfMonth,
  );

  // Group invoices into dates with a bar limit - using a higher limit for monthly view
  _ChartUtils.groupInvoicesByDate(
    dateMap: invoicesByDay,
    filteredInvoices: invoicesWithinRange,
    barLimit: 6,
    errorPrefix: "This Month",
  );

  // Create bar groups with narrower bars due to potentially many days
  final barGroups = _ChartUtils.createBarGroups(
    invoicesByDay,
    barWidth: 4,
    barsSpace: 2,
  );

  // Limit to approximately 8 labels as requested
  const amountOfLabels = 8;
  final interval = _ChartUtils.calculateLabelInterval(daysInMonth, amountOfLabels);

  // Calculate maxY for the chart
  final maxY = _ChartUtils.computeMaxY(barGroups);

  // Create titles with consistent styling
  final titlesData = _ChartUtils.createTitlesData(
    dateMap: invoicesByDay,
    maxY: maxY,
    interval: interval,
    formatLabel: (date) => date.toSimplifiedDateString(),
  );

  return (titlesData, barGroups, maxY);
}

Future<(FlTitlesData, List<BarChartGroupData>, double)> _computeLast30DaysData(
  List<Invoice> invoices,
) async {
  final today = DateTime.now().zeroedTime();
  final startDate = today.subtract(const Duration(days: 29)); // 30 days including today

  // Create date map using utility
  final invoicesByDay = _ChartUtils.createDailyDateMap(
    startDate: startDate,
    endDate: today,
  );

  // Filter invoices for date range
  final invoicesWithinRange = _ChartUtils.filterInvoicesInDateRange(
    invoices,
    startDate,
    today,
  );

  // Group invoices into dates with a bar limit
  _ChartUtils.groupInvoicesByDate(
    dateMap: invoicesByDay,
    filteredInvoices: invoicesWithinRange,
    barLimit: 3,
    errorPrefix: "Last 30 Days",
  );

  // Create bar groups
  final barGroups = _ChartUtils.createBarGroups(
    invoicesByDay,
    barWidth: 4,
    barsSpace: 2,
  );

  // Limit to approximately 8 labels as requested
  const amountOfLabels = 8;
  final interval = _ChartUtils.calculateLabelInterval(30, amountOfLabels);

  // Calculate maxY for the chart
  final maxY = _ChartUtils.computeMaxY(barGroups);

  // Create titles with consistent styling
  final titlesData = _ChartUtils.createTitlesData(
    dateMap: invoicesByDay,
    maxY: maxY,
    interval: interval,
    formatLabel: (date) => date.toSimplifiedDateString(),
  );

  return (titlesData, barGroups, maxY);
}

Future<(FlTitlesData, List<BarChartGroupData>, double)> _computeLastMonthData(
  List<Invoice> invoices,
) async {
  final now = DateTime.now();
  // First day of the current month
  final firstDayOfCurrentMonth = DateTime(now.year, now.month, 1);
  // Last day of the last month is day 0 of the current month
  final endOfLastMonth = firstDayOfCurrentMonth.subtract(const Duration(days: 1)).zeroedTime();
  // First day of the last month
  final startOfLastMonth = DateTime(endOfLastMonth.year, endOfLastMonth.month, 1).zeroedTime();
  final daysInLastMonth = endOfLastMonth.day;

  // Create date map using utility
  final invoicesByDay = _ChartUtils.createDailyDateMap(
    startDate: startOfLastMonth,
    endDate: endOfLastMonth,
  );

  // Filter invoices for date range
  final invoicesWithinRange = _ChartUtils.filterInvoicesInDateRange(
    invoices,
    startOfLastMonth,
    endOfLastMonth,
  );

  // Group invoices into dates with a bar limit
  _ChartUtils.groupInvoicesByDate(
    dateMap: invoicesByDay,
    filteredInvoices: invoicesWithinRange,
    barLimit: 3,
    errorPrefix: "Last Month",
  );

  // Create bar groups with narrower bars due to potentially many days
  final barGroups = _ChartUtils.createBarGroups(
    invoicesByDay,
    barWidth: 4,
    barsSpace: 2,
  );

  // Limit to approximately 8 labels as requested
  const amountOfLabels = 8;
  final interval = _ChartUtils.calculateLabelInterval(daysInLastMonth, amountOfLabels);

  // Calculate maxY for the chart
  final maxY = _ChartUtils.computeMaxY(barGroups);

  // Create titles with consistent styling
  final titlesData = _ChartUtils.createTitlesData(
    dateMap: invoicesByDay,
    maxY: maxY,
    interval: interval,
    formatLabel: (date) => date.toSimplifiedDateString(),
  );

  return (titlesData, barGroups, maxY);
}

Future<(FlTitlesData, List<BarChartGroupData>, double)> _computeThisYearData(
  List<Invoice> invoices,
) async {
  final now = DateTime.now();
  final currentMonth = now.month;
  final startOfYear = DateTime(now.year, 1, 1).zeroedTime();
  final endOfYear = DateTime(now.year, currentMonth, now.day).zeroedTime(); // Current date as end

  // Create monthly date map using utility
  final invoicesByMonth = _ChartUtils.createMonthlyDateMap(
    year: now.year,
    startMonth: 1,
    numberOfMonths: currentMonth,
  );

  // Filter invoices for date range
  final invoicesWithinRange = _ChartUtils.filterInvoicesInDateRange(
    invoices,
    startOfYear,
    endOfYear,
  );

  // For yearly data, we need to group by month
  for (final invoice in invoicesWithinRange) {
    final invDate = invoice.invoiceDate.zeroedTime();
    final monthKey = DateTime(invDate.year, invDate.month, 1);

    if (invoicesByMonth.containsKey(monthKey)) {
      invoicesByMonth[monthKey]!.add(invoice);
    } else {
      printBoxed(
        "Invoice date ${invoice.invoiceDate} (normalized: $invDate) not in this year's map. Map covers $startOfYear to $endOfYear.",
        "Invoice Date Error (This Year)",
      );
    }
  }

  // Create summarized bar groups for yearly view
  final barGroups = _ChartUtils.createSummarizedMonthlyBarGroups(invoicesByMonth);

  // Calculate maxY for the chart
  final maxY = _ChartUtils.computeMaxY(barGroups);

  // Limit to approximately 8 labels as requested
  const amountOfLabels = 8;
  final interval = _ChartUtils.calculateLabelInterval(currentMonth, amountOfLabels);

  // Create titles with consistent styling - for yearly data, show month names with year
  final titlesData = _ChartUtils.createTitlesData(
    dateMap: invoicesByMonth,
    maxY: maxY,
    interval: interval,
    showMonthNames: true,
    showYearInLabel: true, // Include year for clarity
    formatLabel: (date) => _ChartUtils.formatMonthLabel(date, true),
  );

  return (titlesData, barGroups, maxY);
}

extension ZeroableTimeExtension on DateTime {
  DateTime zeroedTime() {
    return copyWith(
      hour: 0,
      minute: 0,
      second: 0,
      millisecond: 0,
      microsecond: 0,
    );
  }

  String toSimplifiedDateString() {
    const months = [
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec"
    ];

    return "${months[month - 1]} ${day.toString().padLeft(2, '0')}";
  }
}
