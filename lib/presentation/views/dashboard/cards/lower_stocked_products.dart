import 'package:easthardware_pms/domain/models/product.dart';
import 'package:easthardware_pms/presentation/bloc/inventory/product_list/product_list_bloc.dart';
import 'package:easthardware_pms/presentation/router/app_routes.dart';
import 'package:easthardware_pms/presentation/widgets/layout/spacing.dart';
import 'package:easthardware_pms/presentation/widgets/text.dart';
import 'package:easthardware_pms/utils/typed_routes.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:provider/provider.dart';
import 'package:scroll_animator/scroll_animator.dart';
import 'package:two_dimensional_scrollables/two_dimensional_scrollables.dart';

class LowerStockedProducts extends StatefulWidget {
  const LowerStockedProducts({super.key});

  @override
  State<LowerStockedProducts> createState() => _LowerStockedProductsState();
}

class _LowerStockedProductsState extends State<LowerStockedProducts> {
  late final AnimatedScrollController verticalScrollController;
  late final AnimatedScrollController horizontalScrollController;

  static const double cellHeight = 36.0;
  static final Map<String, (SpanExtent, Widget Function(Product))> _rowExtents = {
    "Name": (
      const MaxSpanExtent(FixedSpanExtent(180.00), FractionalSpanExtent(0.50)),
      (p) => Text(p.name),
    ),
    "Quantity": (
      const MaxSpanExtent(FixedSpanExtent(120.00), FractionalSpanExtent(0.25)),
      (p) => Text("${p.quantity} ${p.mainUnit}"),
    ),
    "Actions": (
      const MaxSpanExtent(FixedSpanExtent(80.00), RemainingSpanExtent()),
      (p) {
        return Builder(builder: (context) {
          return Align(
            alignment: Alignment.topLeft,
            child: HyperlinkButton(
              onPressed: () {
                ///   Ideally, the createRestockOrder should accept a product that
                ///     needs to be restocked, to allow the user to order automatically.
                context.navigateWithExtra(AppRoutes.admin.createRestockOrder.withProduct, p);
              },
              child: const Text('Order'),
            ),
          );
        });
      },
    ),
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
    final products = context
        .select((ProductListBloc b) => b.state.allProducts)
        .where((p) => p.quantity < p.criticalLevel)
        .toList();
    final matrix = [
      [
        for (final columnName in _rowExtents.keys)
          Text(columnName, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
      for (final product in products) //
        [for (final (_, selector) in _rowExtents.values) selector(product)]
    ];

    return Container(
      color: FluentTheme.of(context).cardColor,
      padding: AppPadding.cardPadding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const DisplayText('Lower Stocked Products'),
          Spacing.v16,
          if (products.isEmpty)
            const Expanded(
              child: Center(
                child: Text('No products are below their critical level.'),
              ),
            )
          else
            Expanded(
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
                columnBuilder: (int index) => TableSpan(
                  extent: _rowExtents.values.elementAt(index).$1,
                ),
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
            ),
        ],
      ),
    );
  }
}
