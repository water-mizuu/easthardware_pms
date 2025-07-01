import 'package:easthardware_pms/domain/models/expense_type.dart';
import 'package:easthardware_pms/domain/models/invoice.dart';
import 'package:easthardware_pms/domain/models/order.dart';
import 'package:easthardware_pms/domain/models/product.dart';
import 'package:easthardware_pms/presentation/bloc/search/search_bloc.dart';
import 'package:easthardware_pms/presentation/widgets/helper/currency_formatter.dart';
import 'package:easthardware_pms/presentation/widgets/layout/spacing.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:scroll_animator/scroll_animator.dart';
import 'package:two_dimensional_scrollables/two_dimensional_scrollables.dart';

class ProductsBody extends SearchTableResult<Product> {
  factory ProductsBody() => instance;
  ProductsBody._()
      : super(
          selector: (b) => b.state.results.products,
          columns: [
            ('ID', (context, p) => p.id.toString()),
            ('SKU', (context, p) => p.sku),
            ('Name', (context, p) => p.name),
            ('Category', (context, p) => p.categoryName.toString()),
          ],
          rowExtents: const {
            0: FixedSpanExtent(64.00),
            1: MaxSpanExtent(
              FixedSpanExtent(160.00),
              FractionalSpanExtent(0.3333),
            ),
            2: MaxSpanExtent(
              FixedSpanExtent(160.00),
              FractionalSpanExtent(0.3333),
            ),
            3: MaxSpanExtent(
              FixedSpanExtent(160.00),
              FractionalSpanExtent(0.3333),
            ),
          },
        );
  static final ProductsBody instance = ProductsBody._();
}

class InvoicesBody extends SearchTableResult<Invoice> {
  factory InvoicesBody() => instance;
  InvoicesBody._()
      : super(
          selector: (b) => b.state.results.invoices,
          columns: [
            ('Invoice No.', (context, p) => p.id.toString()),
            ('Invoice Date', (context, p) => DateFormat('yyyy-MM-dd').format(p.invoiceDate)),
            ('Customer Name', (context, p) => p.customerName),
            ('Payment Reference No.', (context, p) => p.referenceNumber ?? ""),
            ('Memo', (context, p) => p.memo ?? ""),
          ],
          rowExtents: const {
            0: FixedSpanExtent(96.00),
            1: FixedSpanExtent(128.00),
            2: MaxSpanExtent(
              FixedSpanExtent(160.00),
              FractionalSpanExtent(0.3333),
            ),
            3: MaxSpanExtent(
              FixedSpanExtent(160.00),
              FractionalSpanExtent(0.3333),
            ),
            4: MaxSpanExtent(
              FixedSpanExtent(160.00),
              RemainingSpanExtent(),
            ),
          },
        );

  static final InvoicesBody instance = InvoicesBody._();
}

class OrdersBody extends SearchTableResult<Order> {
  factory OrdersBody() => instance;
  OrdersBody._()
      : super(
          selector: (b) => b.state.results.orders,
          columns: [
            ('Order No.', (context, p) => p.id.toString()),
            ('Order Date', (context, p) => DateFormat('yyyy-MM-dd').format(p.orderDate)),
            ('Payee Name', (context, p) => p.payeeName),
            (
              'Expense Type',
              (context, p) => (context.read<SearchBloc>().state)
                  .allExpenseTypes
                  .firstWhere((et) => et.id == p.expenseType,
                      orElse: () => const ExpenseType(name: '-'))
                  .name
            ),
            ('Amount', (context, p) => CurrencyFormatter.full(p.amountDue)),
            ('Memo', (context, p) => p.memo?.limitLength(30) ?? ""),
          ],
          rowExtents: const {
            0: FixedSpanExtent(96.00),
            1: FixedSpanExtent(128.00),
            2: MaxSpanExtent(
              FixedSpanExtent(160.00),
              FractionalSpanExtent(0.3333),
            ),
            3: MaxSpanExtent(
              FixedSpanExtent(120.00),
              FractionalSpanExtent(0.3333),
            ),
            4: MaxSpanExtent(
              FixedSpanExtent(160.00),
              FractionalSpanExtent(0.3333),
            ),
            5: MaxSpanExtent(
              FixedSpanExtent(160.00),
              RemainingSpanExtent(),
            ),
          },
        );

  static final OrdersBody instance = OrdersBody._();
}

extension on String {
  String limitLength(int i) {
    if (length <= i) return this;
    return '${substring(0, i)}...';
  }
}

class SearchTableResult<T> extends StatefulWidget {
  const SearchTableResult({
    required this.selector,
    required this.columns,
    required this.rowExtents,
    super.key,
  });

  final List<T> Function(SearchBloc) selector;
  final List<(String, String Function(BuildContext, T))> columns;
  final Map<int, SpanExtent> rowExtents;

  @override
  State<SearchTableResult<T>> createState() => _SearchTableResultState<T>();
}

class _SearchTableResultState<T> extends State<SearchTableResult<T>> {
  late final AnimatedScrollController verticalScrollController;
  late final AnimatedScrollController horizontalScrollController;

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
    const cellHeight = 36.0;
    const rowPadding = 0.0 + 4.0;

    final results = context.select(widget.selector);
    final matrix = [widget.columns.map((c) => c.$1).toList()]
        .followedBy(results //
            .map((p) => widget.columns.map((c) => c.$2(context, p)).toList())
            .expand((x) => [x]))
        .toList();

    return ColoredBox(
      color: FluentTheme.of(context).cardColor,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: AppPadding.cardPadding.top + (cellHeight + rowPadding) * (results.length + 1),
        ),
        child: Padding(
          padding: AppPadding.cardPadding.copyWith(bottom: 0.0),
          child: Builder(
            builder: (context) {
              if (matrix.isEmpty) {
                return Center(
                  child: Text(
                    'No products found.',
                    style: FluentTheme.of(context).typography.body,
                  ),
                );
              }

              return TableView.builder(
                pinnedRowCount: 1,
                verticalDetails: ScrollableDetails.vertical(
                  controller: verticalScrollController,
                ),
                columnCount: matrix.first.length,
                columnBuilder: (int index) {
                  return TableSpan(
                    extent: widget.rowExtents[index]!,
                    padding: const SpanPadding(trailing: rowPadding),
                  );
                },
                horizontalDetails: ScrollableDetails.horizontal(
                  controller: horizontalScrollController,
                ),
                rowCount: matrix.length,
                rowBuilder: (int index) {
                  return const TableSpan(
                    extent: FixedSpanExtent(cellHeight),
                    padding: SpanPadding(trailing: rowPadding),
                  );
                },
                cellBuilder: (context, vicinity) {
                  return TableViewCell(
                    child: Builder(
                      builder: (context) {
                        final isHeader = vicinity.row == 0;

                        if (isHeader) {
                          return Text(
                            matrix[vicinity.row][vicinity.column],
                            style: FluentTheme.of(context).typography.bodyStrong,
                          );
                        } else {
                          return Text(
                            matrix[vicinity.row][vicinity.column],
                            style: FluentTheme.of(context).typography.body,
                          );
                        }
                      },
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
