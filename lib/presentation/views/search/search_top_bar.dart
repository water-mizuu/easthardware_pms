import 'dart:async';

import 'package:easthardware_pms/domain/models/invoice.dart';
import 'package:easthardware_pms/domain/models/order.dart';
import 'package:easthardware_pms/domain/models/product.dart';
import 'package:easthardware_pms/presentation/bloc/billing/invoicelist/invoice_list_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/inventory/product_list/product_list_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/order/orderlist/order_list_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/search/search_bloc.dart';
import 'package:easthardware_pms/presentation/router/app_routes.dart';
import 'package:easthardware_pms/presentation/views/navigation/common_side_panel_mixin.dart';
import 'package:easthardware_pms/presentation/widgets/layout/spacing.dart';
import 'package:easthardware_pms/presentation/widgets/text.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

class SearchPage extends StatefulWidget {
  const SearchPage(this.shell, {super.key});

  final StatefulNavigationShell shell;

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  late List<Product>? _products;
  late List<Invoice>? _invoices;
  late List<Order>? _orders;

  late final SearchBloc _searchBloc;

  List<SingleChildWidget> get providers {
    return [
      BlocProvider<SearchBloc>.value(value: _searchBloc),
    ];
  }

  @override
  void initState() {
    super.initState();

    _products = null;
    _invoices = null;
    _orders = null;

    _searchBloc = SearchBloc();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final products = context.watch<ProductListBloc>().state.allProducts;
    final invoices = context.watch<InvoiceListBloc>().state.invoices;
    final orders = context.watch<OrderListBloc>().state.allOrders;
    if (products != _products || invoices != _invoices || orders != _orders) {
      _searchBloc.add(
        SearchDependentsUpdated(
          products: products,
          invoices: invoices,
          orders: orders,
        ),
      );
    }
  }

  @override
  void dispose() {
    unawaited(_searchBloc.close());

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: providers,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(padding: AppPadding.panePadding, child: _PageHeader()),
          Spacing.v4,
          Expanded(child: _SearchMenu(widget.shell))
        ],
      ),
    );
  }
}

class _SearchMenu extends StatelessWidget with NavigationPanelMixin {
  const _SearchMenu(this.shell);

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppPadding.panePadding.horizontal / 2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SearchElement(),
          Spacing.v12,
          Expanded(
            child: Builder(builder: (context) {
              final query = context.select((SearchBloc bloc) => bloc.state.query);
              final results = context.select((SearchBloc bloc) => bloc.state.results);

              String addResults(String title, int result) {
                if (query.isEmpty) {
                  return title;
                }
                return '$title ($result result${result == 1 ? '' : 's'})';
              }

              return NavigationView(
                clipBehavior: Clip.hardEdge,
                contentShape: const RoundedRectangleBorder(),
                paneBodyBuilder: (_, __) => SingleChildScrollView(child: shell),
                pane: NavigationPane(
                  displayMode: PaneDisplayMode.top,
                  selected: shell.currentIndex,
                  onItemPressed: (index) {
                    shell.goBranch(index);
                  },
                  items: [
                    navItem(
                      title: addResults('Products', results.products.length),
                      route: AppRoutes.admin.search.products,
                    ),
                    navItem(
                      title: addResults('Invoices', results.invoices.length),
                      route: AppRoutes.admin.search.invoices,
                    ),
                    navItem(
                      title: addResults('Orders', results.orders.length),
                      route: AppRoutes.admin.search.orders,
                    ),
                  ],
                ),
              );
            }),
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
