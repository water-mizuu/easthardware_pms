import 'dart:math';

import 'package:easthardware_pms/domain/models/invoice.dart';
import 'package:easthardware_pms/presentation/bloc/billing/invoicelist/invoice_list_bloc.dart';
import 'package:easthardware_pms/presentation/widgets/helper/currency_formatter.dart';
import 'package:easthardware_pms/presentation/widgets/layout/spacing.dart';
import 'package:easthardware_pms/presentation/widgets/text.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:provider/provider.dart';
import 'package:scroll_animator/scroll_animator.dart';
import 'package:two_dimensional_scrollables/two_dimensional_scrollables.dart';

class LatestSales extends StatelessWidget {
  const LatestSales({super.key});

  @override
  Widget build(BuildContext context) {
    final invoices = context.select((InvoiceListBloc b) => b.state.invoices);

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
              const _RecentSalesPlaceholder()
          ],
        ),
      ),
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
    "Total": (const FixedSpanExtent(120), (i) => Text(CurrencyFormatter.full(i.amountDue))),
    "Payment Method": (
      const MaxSpanExtent(
        FixedSpanExtent(120.00),
        FractionalSpanExtent(0.33),
      ),
      (i) => Text({0: "Cash", 1: "GCash"}[i.paymentMethod] ?? ""),
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
    final invoices = context.select((InvoiceListBloc b) => b.state.invoices);
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
