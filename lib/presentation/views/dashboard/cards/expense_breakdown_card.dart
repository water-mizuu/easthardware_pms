import 'dart:async';
import 'dart:math';

import 'package:easthardware_pms/domain/models/order.dart';
import 'package:easthardware_pms/presentation/bloc/order/expense_type_list/expense_type_list_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/order/orderlist/order_list_bloc.dart';
import 'package:easthardware_pms/presentation/widgets/layout/spacing.dart';
import 'package:easthardware_pms/presentation/widgets/text.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

enum ExpenseBreakdownChoice {
  last7Days,
  thisWeek,
  thisMonth,
  last30Days,
  lastMonth,
}

/// FIXME: Expense type table

class ExpenseBreakdownCard extends StatelessWidget {
  const ExpenseBreakdownCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: FluentTheme.of(context).cardColor,
      padding: AppPadding.cardPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const DisplayText('Expense Breakdown'),
          Spacing.v16,
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 200),
            child: const _ExpensesBreakdownCardGraph(),
          ),
        ],
      ),
    );
  }
}

class _ExpensesBreakdownCardGraph extends StatefulWidget {
  const _ExpensesBreakdownCardGraph();

  @override
  State<_ExpensesBreakdownCardGraph> createState() => _ExpensesBreakdownCardGraphState();
}

class _ExpensesBreakdownCardGraphState extends State<_ExpensesBreakdownCardGraph> {
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
      if (kDebugMode && orders.isEmpty) {
        // For debugging purposes, we can generate some random data
        _orders = List.generate(10, (index) {
          return Order(
            id: index,
            payeeName: "Anonymous",
            amountDue: Random().nextDouble() * 1000.0,
            expenseType: index % 8,
            orderDate: DateTime.now(), // Simulating 3 different expense types
            paymentMethod: Random().nextInt(8),
            referenceNumber: "REF-${index + 1}", creationDate: DateTime.now(), creatorId: 1,
          );
        });
      }
      _updatePieChartData(_orders!);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_pieChartData == null) {
      return const Center(child: _ExpensesBreakdownPlaceholder());
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(child: PieChart(_pieChartData!)),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final value in _pieChartData!.sections)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 16,
                      height: 16,
                      color: value.color,
                    ),
                    Spacing.h8,
                    if (value.badgeWidget case Opacity(child: Text(:final data?)))
                      Text(data, style: const TextStyle(fontSize: 12)),
                  ],
                ),
              ),
          ],
        )
      ],
    );
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
      enabled: true,
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
    for (final (i, MapEntry(key: id, value: amount)) in categoryTotals.entries.indexed) {
      final percentage = total > 0 ? (amount / total) * 100.0 : 0.0;

      final name = context
          .read<ExpenseTypeListBloc>()
          .state
          .expenseTypes
          .where((e) => e.id == id)
          .firstOrNull
          ?.name;

      sections.add(
        PieChartSectionData(
          value: percentage,
          title: '${percentage.toStringAsFixed(1)}%',
          radius: 64.0,
          badgeWidget: Opacity(
            opacity: 0.0,
            child: Text(
              name ?? 'Other',
              style: const TextStyle(color: Colors.white),
            ),
          ),
          color: HSLColor.fromAHSL(1.0, ((i / categoryTotals.length) * 360), 0.5, 0.50).toColor(),
          titleStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
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
