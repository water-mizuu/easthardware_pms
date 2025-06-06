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
                  children: const [
                    SearchBody(),
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

class SearchBody extends StatelessWidget {
  const SearchBody({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SubheadingText('Inventory Summary'),
        TextBox(
          onChanged: (value) => context.read<SearchBloc>().add(SearchQueryUpdated(value)),
        ),
        Spacing.v8,
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final result in context.watch<SearchBloc>().state.results.products)
              Text(
                (result.name).toString(),
                style: FluentTheme.of(context).typography.body,
              ),
          ],
        ),
      ].withSpacing(() => Spacing.v8),
    );
  }
}
