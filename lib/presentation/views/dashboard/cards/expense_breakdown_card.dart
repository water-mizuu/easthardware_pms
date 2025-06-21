import 'dart:async';
import 'dart:convert';

import 'package:easthardware_pms/domain/models/expense_type.dart';
import 'package:easthardware_pms/domain/models/order.dart';
import 'package:easthardware_pms/presentation/bloc/order/expense_type_list/expense_type_list_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/order/orderlist/order_list_bloc.dart';
import 'package:easthardware_pms/presentation/router/app_router.dart';
import 'package:easthardware_pms/presentation/widgets/animated_single_child_scroll_view.dart';
import 'package:easthardware_pms/presentation/widgets/helper/currency_formatter.dart';
import 'package:easthardware_pms/presentation/widgets/layout/spacing.dart';
import 'package:easthardware_pms/presentation/widgets/text.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' show Material;
import 'package:flutter_bloc/flutter_bloc.dart';

enum ExpenseBreakdownChoice {
  last7Days,
  thisWeek,
  thisMonth,
  last30Days,
  lastMonth,
}

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
  late final GlobalKey chartKey = GlobalKey();

  OverlayEntry? _overlayEntry;

  late List<Order>? _orders;
  late List<ExpenseType>? _expenseTypes;
  late PieChartData? _pieChartData;
  late void Function()? _requestCanceller;

  @override
  void initState() {
    super.initState();

    _orders = null;
    _expenseTypes = null;
    _pieChartData = null;
    _requestCanceller = null;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    var isPieChartDataDirty = false;
    final orders = context.watch<OrderListBloc>().state.allOrders;
    if (_orders != orders) {
      _orders = orders;
      isPieChartDataDirty |= true;
    }

    final expenseTypes = context.watch<ExpenseTypeListBloc>().state.expenseTypes;
    if (_expenseTypes != expenseTypes) {
      _expenseTypes = expenseTypes;
      isPieChartDataDirty |= true;
    }

    if (isPieChartDataDirty) {
      _updatePieChartData();
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
        Expanded(child: PieChart(_pieChartData!, key: chartKey)),
        AnimatedSingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
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
                        if (jsonDecode(data) case {'title': final title?})
                          Text(title, style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
            ],
          ),
        )
      ],
    );
  }

  void _updatePieChartData() {
    _requestCanceller?.call();
    var isCancelled = false;

    _requestCanceller = () => isCancelled = true;
    unawaited(() async {
      final data = await _createPieChartData();
      if (!mounted || isCancelled) return;
      setState(() => _pieChartData = data);
    }());
  }

  Future<PieChartData> _createPieChartData() async {
    final pieTouchData = PieTouchData(
      enabled: true,
      touchCallback: (event, response) {
        final section = response?.touchedSection?.touchedSection;

        if (_overlayEntry != null) {
          _overlayEntry?.remove();
          _overlayEntry = null;
        }

        if (section case final section? when event is! FlPointerExitEvent) {
          final position = event.localPosition;
          if (position == null) {
            return;
          }

          if (chartKey.currentContext?.findRenderObject() case final RenderBox box) {
            final globalOffset = box.localToGlobal(position);
            final type = switch (section.badgeWidget) {
              Opacity(child: Text(:final data?)) => data,
              _ => null,
            };

            /// If the type is null, we don't have a valid section to display.
            if (type == null) return;
            final decoded = jsonDecode(type) as Map<String, dynamic>;
            final {
              'title': String title,
              'amount': double amount,
              'percentage': double percentage,
            } = decoded;

            /// If we are touching a section, show the overlay at the touch position.
            _overlayEntry = OverlayEntry(
              builder: (context) {
                return Positioned(
                  left: globalOffset.dx,
                  top: globalOffset.dy,
                  child: IgnorePointer(
                    child: Material(
                      color: const Color(0xfffafafa),
                      elevation: 8.0,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: IntrinsicWidth(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(title),
                              Spacing.v4,
                              const Divider(style: DividerThemeData(thickness: 1.0)),
                              Spacing.v4,
                              Text("Amount: ${CurrencyFormatter.full(amount)}"),
                              Text("Percentage: ${percentage.toStringAsFixed(1)}%"),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            );

            Overlay.of(overlayWidgetKey.currentContext!).insert(_overlayEntry!);
          }
        }
      },
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

    final sections = await _createPieChartSections();

    return PieChartData(
      pieTouchData: pieTouchData,
      borderData: borderData,
      sectionsSpace: 2,
      sections: sections,
    );
  }

  Future<List<PieChartSectionData>> _createPieChartSections() async {
    final categoryTotals = <int, double>{};

    for (final order in _orders ?? <Order>[]) {
      final category = order.expenseType;
      categoryTotals[category] = (categoryTotals[category] ??= 0) + order.amountDue;
    }

    final total = categoryTotals.values.fold(0.0, (sum, value) => sum + value);
    final sections = <PieChartSectionData>[];

    final expenseTypes = _expenseTypes ?? <ExpenseType>[];
    for (final (i, MapEntry(key: id, value: amount)) in categoryTotals.entries.indexed) {
      final percentage = total > 0 ? (amount / total) * 100.0 : 0.0;
      final name = expenseTypes.where((e) => e.id == id).firstOrNull?.name;

      sections.add(
        PieChartSectionData(
          value: percentage,
          title: percentage > 5 ? '${percentage.toStringAsFixed(1)}%' : '',
          radius: 64.0,
          badgeWidget: Opacity(
            opacity: 0.0,
            child: Text(
              jsonEncode({
                "title": name ?? 'ID $id',
                'percentage': percentage,
                'amount': amount,
              }),
              style: const TextStyle(color: Colors.white),
            ),
          ),
          color: HSLColor.fromAHSL(1.0, (i / categoryTotals.length) * 360, 0.5, 0.50).toColor(),
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
