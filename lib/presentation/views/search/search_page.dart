import 'dart:math';

import 'package:easthardware_pms/domain/models/invoice.dart';
import 'package:easthardware_pms/domain/models/order.dart';
import 'package:easthardware_pms/domain/models/product.dart';
import 'package:easthardware_pms/presentation/bloc/billing/invoicelist/invoice_list_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/inventory/product_list/product_list_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/order/orderlist/order_list_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/search/search_bloc.dart';
import 'package:easthardware_pms/presentation/widgets/layout/spacing.dart';
import 'package:easthardware_pms/presentation/widgets/text.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:scroll_animator/scroll_animator.dart';
import 'package:two_dimensional_scrollables/two_dimensional_scrollables.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  late ProductListBloc? _productListBloc;
  late InvoiceListBloc? _invoiceListBloc;
  late OrderListBloc? _orderListBloc;

  late final SearchBloc _searchBloc;
  late final AnimatedScrollController _scrollController;

  List<SingleChildWidget> get providers {
    return [
      BlocProvider<SearchBloc>.value(value: _searchBloc),
    ];
  }

  @override
  void initState() {
    super.initState();

    _productListBloc = null;
    _invoiceListBloc = null;
    _orderListBloc = null;

    _searchBloc = SearchBloc();
    _scrollController = AnimatedScrollController(animationFactory: const ChromiumEaseInOut());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final productListBloc = context.watch<ProductListBloc>();
    final invoiceListBloc = context.watch<InvoiceListBloc>();
    final orderListBloc = context.watch<OrderListBloc>();
    if (productListBloc != _productListBloc ||
        invoiceListBloc != _invoiceListBloc ||
        orderListBloc != _orderListBloc) {
      _searchBloc.add(
        SearchDependentsUpdated(
          products: productListBloc.state.allProducts,
          invoices: invoiceListBloc.state.allInvoices,
          orders: orderListBloc.state.allOrders,
        ),
      );
    }
  }

  @override
  void dispose() {
    _searchBloc.close();
    _scrollController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: providers,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: AppPadding.panePadding,
            child: _PageHeader(),
          ),
          Spacing.v4,
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: AppPadding.panePadding.horizontal / 2,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _SearchElement(),
                    ProductsBody(),
                    InvoicesBody(),
                    OrdersBody(),
                  ].withSpacing(() => Spacing.v16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const HeadingText('Search'),
        const Spacer(flex: 1),
      ].withSpacing(() => Spacing.h16),
    );
  }
}

class _SearchElement extends StatelessWidget {
  const _SearchElement();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text("Search keyword:"),
        Spacing.h8,
        Expanded(
          child: TextBox(
            placeholder: 'Enter search keyword; e.g. product name, invoice number, etc.',
            onChanged: (value) => context.read<SearchBloc>().add(SearchQueryUpdated(value)),
          ),
        ),
      ],
    );
  }
}

class ProductsBody extends SearchTableResult<Product> {
  ProductsBody({super.key})
      : super(
          title: 'Products',
          selector: (b) => b.state.results.products,
          columns: [
            ('ID', (p) => p.id.toString()),
            ('SKU', (p) => p.sku),
            ('Name', (p) => p.name),
            ('Price', (p) => p.categoryName.toString()),
          ],
          rowExtents: {
            0: const TableSpan(extent: FixedSpanExtent(64.00)),
            1: const TableSpan(
              extent: MinSpanExtent(
                FixedSpanExtent(320.00),
                FractionalSpanExtent(0.3333),
              ),
            ),
            2: const TableSpan(
              extent: MinSpanExtent(
                FixedSpanExtent(320.00),
                FractionalSpanExtent(0.3333),
              ),
            ),
            3: const TableSpan(
              extent: MinSpanExtent(
                FixedSpanExtent(320.00),
                FractionalSpanExtent(0.3333),
              ),
            ),
          },
        );
}

class InvoicesBody extends SearchTableResult<Invoice> {
  InvoicesBody({super.key})
      : super(
          title: 'Invoices',
          selector: (b) => b.state.results.invoices,
          columns: [
            ('ID', (p) => p.id.toString()),
            ('Memo', (p) => p.memo ?? ""),
          ],
          rowExtents: {
            0: const TableSpan(extent: FixedSpanExtent(64.00)),
            1: const TableSpan(
              extent: MinSpanExtent(
                FixedSpanExtent(320.00),
                RemainingSpanExtent(),
              ),
            ),
          },
        );
}

class OrdersBody extends SearchTableResult<Order> {
  OrdersBody({super.key})
      : super(
          title: 'Products',
          selector: (b) => b.state.results.orders,
          columns: [
            ('ID', (p) => p.id.toString()),
            ('Payee Name', (p) => p.payeeName),
          ],
          rowExtents: {
            0: const TableSpan(extent: FixedSpanExtent(64.00)),
            1: const TableSpan(
              extent: MinSpanExtent(
                FixedSpanExtent(320.00),
                RemainingSpanExtent(),
              ),
            ),
          },
        );
}

class SearchTableResult<T> extends StatefulWidget {
  const SearchTableResult({
    required this.title,
    required this.selector,
    required this.columns,
    required this.rowExtents,
    super.key,
  });

  final String title;
  final List<T> Function(SearchBloc) selector;
  final List<(String, String Function(T))> columns;
  final Map<int, TableSpan> rowExtents;

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
        .followedBy(results.map((p) => widget.columns.map((c) => c.$2(p)).toList()))
        .toList();

    return ColoredBox(
      color: FluentTheme.of(context).cardColor,
      child: Padding(
        padding: AppPadding.cardPadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (context.read<SearchBloc>().state.query.isEmpty)
              SubheadingText(widget.title)
            else
              SubheadingText('${widget.title} (${results.length} results)'),
            Spacing.v8,
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: min(
                  AppPadding.cardPadding.top + //
                      cellHeight * (4 + 1) +
                      rowPadding * (4 + 1),
                  AppPadding.cardPadding.top +
                      cellHeight * (results.length + 1) +
                      rowPadding * (results.length + 1),
                ),
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
                        return widget.rowExtents[index]!;
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
                      cellBuilder: (BuildContext context, TableVicinity vicinity) {
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
            )
          ],
        ),
      ),
    );
  }
}

class RemainingSpanExtent extends SpanExtent {
  /// Creates a [RemainingSpanExtent].
  const RemainingSpanExtent();

  @override
  double calculateExtent(SpanExtentDelegate delegate) {
    print((
      'RemainingSpanExtent.calculateExtent called',
      '${delegate.viewportExtent}, ${delegate.precedingExtent}',
    ));
    return max(0.0, delegate.viewportExtent - delegate.precedingExtent);
  }
}
