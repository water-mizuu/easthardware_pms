import 'dart:math';

import 'package:easthardware_pms/domain/models/product.dart';
import 'package:easthardware_pms/presentation/bloc/inventory/product_list/product_list_bloc.dart';
import 'package:easthardware_pms/presentation/widgets/layout/spacing.dart';
import 'package:easthardware_pms/presentation/widgets/text.dart';
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
  static const int maxRows = 4;

  late final AnimatedScrollController verticalScrollController;
  late final AnimatedScrollController horizontalScrollController;

  static const double cellHeight = 36.0;
  static final Map<String, (SpanExtent, Widget Function(Product))> _rowExtents = {
    "ID": (const FixedSpanExtent(60), (p) => Text(p.id.toString())),
    "Name": (
      const MaxSpanExtent(
        FixedSpanExtent(240.00),
        FractionalSpanExtent(0.33),
      ),
      (p) => Text(p.name),
    ),
    "Category": (
      const MaxSpanExtent(
        FixedSpanExtent(80.00),
        FractionalSpanExtent(0.33),
      ),
      (p) => Text(p.categoryName ?? ""),
    ),
    "Price": (const FixedSpanExtent(120), (p) => Text(p.salePrice.toString())),
    "Cost": (const FixedSpanExtent(120), (p) => Text(p.orderCost.toString())),
    "Quantity": (const FixedSpanExtent(120), (p) => Text(p.quantity.toString())),
    "Actions": (
      const MaxSpanExtent(
        FixedSpanExtent(80.00),
        RemainingSpanExtent(),
      ),
      (p) => const Text("Edit"),
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
    final products = context.select((ProductListBloc b) => b.state.allProducts);
    final matrix = [
      [
        for (final columnName in _rowExtents.keys)
          Text(columnName, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
      for (final product in products) //
        [for (final (_, selector) in _rowExtents.values) selector(product)]
    ];

    return ColoredBox(
      color: FluentTheme.of(context).cardColor,
      child: Padding(
        padding: AppPadding.cardPadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const DisplayText('Lower Stocked Products'),
            Spacing.v16,
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: cellHeight * min(1 + maxRows, matrix.length)),
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
      ),
    );
  }
}
