import 'dart:async';

import 'package:easthardware_pms/domain/models/order.dart';
import 'package:easthardware_pms/presentation/bloc/order/orderlist/order_list_bloc.dart';
import 'package:easthardware_pms/presentation/widgets/layout/spacing.dart';
import 'package:easthardware_pms/presentation/widgets/text.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

enum ExpenseBreakdownChoice {
  last7Days,
  thisWeek,
  thisMonth,
  last30Days,
  lastMonth,
}

class ProfitAndLossCard extends StatelessWidget {
  const ProfitAndLossCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: FluentTheme.of(context).cardColor,
      padding: AppPadding.cardPadding,
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DisplayText('Profit and Loss'),
          Spacing.v16,
          Expanded(child: _ProfitAndLossCardGraph()),
        ],
      ),
    );
  }
}

class _ProfitAndLossCardGraph extends StatefulWidget {
  const _ProfitAndLossCardGraph();

  @override
  State<_ProfitAndLossCardGraph> createState() => _ProfitAndLossCardGraphState();
}

class _ProfitAndLossCardGraphState extends State<_ProfitAndLossCardGraph> {
  late List<Order>? _orders;
  late PieChartData? _pieChartData;
  late void Function()? _requestCanceller;

  @override
  void initState() {
    super.initState();

    _orders = null;
    _pieChartData = null;
    _requestCanceller = null;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final orders = context.watch<OrderListBloc>().state.allOrders;
    if (_orders != orders) {
      _orders = orders;
      _updatePieChartData(orders);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_pieChartData == null || (_orders != null && _orders!.isEmpty)) {
      return const Center(child: _ExpensesBreakdownPlaceholder());
    } else {
      return PieChart(_pieChartData!);
    }
  }

  void _updatePieChartData(List<Order> invoices) {
    _requestCanceller?.call();
    var isCancelled = false;

    _requestCanceller = () => isCancelled = true;
    unawaited(() async {
      final data = await _createPieChartData(invoices);
      if (!mounted || isCancelled) return;
      setState(() => _pieChartData = data);
    }());
  }

  Future<PieChartData> _createPieChartData(List<Order> orders) async {
    final pieTouchData = PieTouchData(
      enabled: false,
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

    final sections = await _createPieChartSections(orders);

    return PieChartData(
      pieTouchData: pieTouchData,
      borderData: borderData,
      sectionsSpace: 2,
      sections: sections,
    );
  }

  Future<List<PieChartSectionData>> _createPieChartSections(List<Order> orders) async {
    final categoryTotals = <int, double>{};

    for (final order in orders) {
      final category = order.expenseType;
      categoryTotals[category] = (categoryTotals[category] ??= 0) + order.amountDue;
    }

    final total = categoryTotals.values.fold(0.0, (sum, value) => sum + value);
    final sections = <PieChartSectionData>[];
    for (final (i, MapEntry(key: category, value: amount)) in categoryTotals.entries.indexed) {
      final percentage = total > 0 ? (amount / total) * 100.0 : 0.0;

      sections.add(
        PieChartSectionData(
          value: percentage,
          title: 'Category $category (${percentage.toStringAsFixed(1)}%)',
          color: HSLColor.fromAHSL(1.0, 0.5 + (i / 128), 0.5, 0.5).toColor(),
          titleStyle: const TextStyle(fontSize: 12, color: Colors.white),
        ),
      );
    }

    return sections;
  }
}

class _ExpensesBreakdownPlaceholder extends StatelessWidget {
  const _ExpensesBreakdownPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(FluentIcons.report_alert, size: 42.0),
          SubheadingText("No orders recorded."),
          Spacing.v8,
          GrayText("Please add some orders to view them here."),
        ],
      ),
    );
  }
}
