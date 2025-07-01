import 'package:easthardware_pms/presentation/bloc/billing/invoicelist/invoice_list_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/order/orderlist/order_list_bloc.dart';
import 'package:easthardware_pms/presentation/views/dashboard/cards/sales_overview.dart';
import 'package:easthardware_pms/presentation/widgets/helper/currency_formatter.dart';
import 'package:easthardware_pms/presentation/widgets/layout/spacing.dart';
import 'package:easthardware_pms/presentation/widgets/text.dart';
import 'package:easthardware_pms/utils/duration.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:provider/provider.dart';

enum ProfitLossTimeframe {
  last7Days,
  thisWeek,
  last30Days,
  thisMonth,
  thisYear,
  allTime;

  String get displayName {
    return switch (this) {
      last7Days => 'Last 7 days',
      thisWeek => 'This week',
      last30Days => 'Last 30 days',
      thisMonth => 'This month',
      thisYear => 'This year',
      allTime => 'All time',
    };
  }

  String get displayText {
    return switch (this) {
      last7Days => 'last 7 days',
      thisWeek => 'this week',
      last30Days => 'last 30 days',
      thisMonth => 'this month',
      thisYear => 'this year',
      allTime => 'all time',
    };
  }
}

class ProfitAndLossCard extends StatelessWidget {
  const ProfitAndLossCard({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ProfitAndLossChangeNotifier(),
      child: Container(
        decoration: BoxDecoration(color: FluentTheme.of(context).cardColor),
        padding: AppPadding.cardPadding,
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ProfitAndLossTitle(),
            Spacing.v16,
            Expanded(child: _ProfitAndLossContent()),
          ],
        ),
      ),
    );
  }
}

class _ProfitAndLossTitle extends StatelessWidget {
  const _ProfitAndLossTitle();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const DisplayText('Profit and Loss'),
              Builder(builder: (context) {
                final timeframe = context.watch<ProfitAndLossChangeNotifier>().timeframe;

                return GrayText('Net profit and payment status for ${timeframe.displayText}');
              }),
            ],
          ),
        ),
        ComboBox<ProfitLossTimeframe>(
          value: context.select((ProfitAndLossChangeNotifier notifier) => notifier.timeframe),
          items: [
            for (final value in ProfitLossTimeframe.values)
              ComboBoxItem(
                value: value,
                child: Text(value.displayName),
              ),
          ],
          onChanged: (value) {
            if (value == null) return;

            context.read<ProfitAndLossChangeNotifier>().setTimeframe(value);
          },
        ),
      ],
    );
  }
}

class _ProfitAndLossContent extends StatelessWidget {
  const _ProfitAndLossContent();

  @override
  Widget build(BuildContext context) {
    final timeframe = context.select((ProfitAndLossChangeNotifier n) => n.timeframe);
    final invoiceState = context.watch<InvoiceListBloc>().state;
    final orderState = context.watch<OrderListBloc>().state;

    final now = DateTime.now();

    // Calculate date range based on selected timeframe
    final (startDate, endDate) = _getDateRange(now, timeframe);

    // Calculate income from invoices for the selected period
    final incomeInvoices = invoiceState.invoices.where((invoice) {
      return invoice.invoiceDate.isAfter(startDate.subtract(1.days).zeroedTime()) &&
          invoice.invoiceDate.isBefore(endDate.add(const Duration(days: 1)));
    }).toList();

    final totalIncomeDue = incomeInvoices.fold(0.0, (s, i) => s + i.amountDue);
    final totalIncomePaid = incomeInvoices.fold(0.0, (s, i) => s + (i.amountPaid ?? 0.0));

    // Calculate expenses from orders for the selected period
    final expenseOrders = orderState.allOrders.where((order) {
      return order.orderDate.isAfter(startDate.subtract(1.days).zeroedTime()) &&
          order.orderDate.isBefore(endDate.add(const Duration(days: 1)));
    }).toList();

    final totalExpenses = expenseOrders.fold(0.0, (s, o) => s + o.amountDue);
    final netProfit = totalIncomePaid - totalExpenses;
    final profitPercentage =
        totalIncomePaid > 0 ? ((netProfit / totalIncomePaid) * 100).round() : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Net profit section
        const SizedBox(height: 8),
        Row(
          children: [
            Text(
              netProfit < 0 //
                  ? '-${CurrencyFormatter.full(netProfit.abs())}'
                  : CurrencyFormatter.full(netProfit),
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    FluentIcons.info,
                    size: 12,
                    color: Colors.blue,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$profitPercentage%',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Payment status summary
        if (totalIncomeDue > 0) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: FluentTheme.of(context).cardColor.withOpacity(0.5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: FluentTheme.of(context).resources.dividerStrokeColorDefault,
                width: 0.5,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Payment Status',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: FluentTheme.of(context).resources.textFillColorSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${((totalIncomePaid / totalIncomeDue) * 100).round()}% collected',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: totalIncomePaid >= totalIncomeDue
                        ? Colors.green.withOpacity(0.1)
                        : totalIncomePaid > 0
                            ? Colors.orange.withOpacity(0.1)
                            : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    totalIncomePaid >= totalIncomeDue
                        ? 'Fully Paid'
                        : totalIncomePaid > 0
                            ? 'Partially Paid'
                            : 'Unpaid',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: totalIncomePaid >= totalIncomeDue
                          ? Colors.green
                          : totalIncomePaid > 0
                              ? Colors.orange
                              : Colors.red,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Sales section with paid/unpaid split
        _SalesBar(
          label: 'Sales',
          totalAmount: totalIncomeDue,
          paidAmount: totalIncomePaid,
          unpaidAmount: totalIncomeDue - totalIncomePaid,
          color: Colors.green,
        ),
        const SizedBox(height: 16),

        // Expenses section
        _FinancialBar(
          label: 'Expenses',
          amount: totalExpenses,
          color: Colors.teal,
        ),
      ],
    );
  }

  // Helper function to calculate date ranges based on timeframe
  (DateTime, DateTime) _getDateRange(DateTime now, ProfitLossTimeframe timeframe) {
    switch (timeframe) {
      case ProfitLossTimeframe.last7Days:
        final startDate = now.subtract(const Duration(days: 7));
        return (startDate, now);

      case ProfitLossTimeframe.thisWeek:
        final weekday = now.weekday;
        final startOfWeek = now.subtract(Duration(days: weekday - 1));
        return (startOfWeek, now);

      case ProfitLossTimeframe.last30Days:
        final startDate = now.subtract(const Duration(days: 30));
        return (startDate, now);

      case ProfitLossTimeframe.thisMonth:
        final startOfMonth = DateTime(now.year, now.month, 1);
        return (startOfMonth, now);

      case ProfitLossTimeframe.thisYear:
        final startOfYear = DateTime(now.year, 1, 1);
        return (startOfYear, now);

      case ProfitLossTimeframe.allTime:
        final startDate = DateTime(2000, 1, 1); // Arbitrary start date
        return (startDate, now);
    }
  }
}

class _SalesBar extends StatelessWidget {
  const _SalesBar({
    required this.label,
    required this.totalAmount,
    required this.paidAmount,
    required this.unpaidAmount,
    required this.color,
  });

  final String label;
  final double totalAmount;
  final double paidAmount;
  final double unpaidAmount;
  final Color color;

  @override
  Widget build(BuildContext context) {
    // Calculate percentages for the split bar
    final paidPercentage = totalAmount > 0 ? (paidAmount / totalAmount) : 0.0;
    final unpaidPercentage = totalAmount > 0 ? (unpaidAmount / totalAmount) : 0.0;

    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              CurrencyFormatter.full(totalAmount),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: FluentTheme.of(context).resources.textFillColorSecondary,
              ),
            ),
            const SizedBox(height: 4),
            // Show breakdown if there are both paid and unpaid amounts
            if (paidAmount > 0 && unpaidAmount > 0) ...[
              Text(
                '${CurrencyFormatter.full(paidAmount)} paid',
                style: TextStyle(
                  fontSize: 10,
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '${CurrencyFormatter.full(unpaidAmount)} pending',
                style: TextStyle(
                  fontSize: 10,
                  color: color.withOpacity(0.6),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ] else if (paidAmount > 0) ...[
              Text(
                'Fully paid',
                style: TextStyle(
                  fontSize: 10,
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ] else if (unpaidAmount > 0) ...[
              Text(
                'Unpaid',
                style: TextStyle(
                  fontSize: 10,
                  color: color.withOpacity(0.6),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
        const Spacer(),
        Expanded(
          child: Container(
            height: 20,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
            ),
            child: totalAmount > 0
                ? Row(
                    children: [
                      // Paid portion
                      if (paidPercentage > 0)
                        Expanded(
                          flex: (paidPercentage * 100).round(),
                          child: Container(
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(4),
                                bottomLeft: const Radius.circular(4),
                                topRight:
                                    unpaidPercentage > 0 ? Radius.zero : const Radius.circular(4),
                                bottomRight:
                                    unpaidPercentage > 0 ? Radius.zero : const Radius.circular(4),
                              ),
                            ),
                          ),
                        ),
                      // Unpaid portion
                      if (unpaidPercentage > 0)
                        Expanded(
                          flex: (unpaidPercentage * 100).round(),
                          child: Container(
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.3),
                              borderRadius: BorderRadius.only(
                                topLeft:
                                    paidPercentage > 0 ? Radius.zero : const Radius.circular(4),
                                bottomLeft:
                                    paidPercentage > 0 ? Radius.zero : const Radius.circular(4),
                                topRight: const Radius.circular(4),
                                bottomRight: const Radius.circular(4),
                              ),
                            ),
                          ),
                        ),
                    ],
                  )
                : Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}

class _FinancialBar extends StatelessWidget {
  const _FinancialBar({
    required this.label,
    required this.amount,
    required this.color,
  });

  final String label;
  final double amount;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              CurrencyFormatter.full(amount),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: FluentTheme.of(context).resources.textFillColorSecondary,
              ),
            ),
          ],
        ),
        const Spacer(),
        Expanded(
          child: Container(
            height: 20,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
      ],
    );
  }
}

class ProfitAndLossChangeNotifier extends ChangeNotifier {
  ProfitLossTimeframe _timeframe = ProfitLossTimeframe.last30Days;

  ProfitLossTimeframe get timeframe => _timeframe;
  void setTimeframe(ProfitLossTimeframe newTimeframe) {
    if (_timeframe != newTimeframe) {
      _timeframe = newTimeframe;
      notifyListeners();
    }
  }
}
