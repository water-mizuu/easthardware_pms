import 'package:easthardware_pms/domain/models/product.dart';
import 'package:easthardware_pms/presentation/bloc/inventory/product_list/product_list_bloc.dart';
import 'package:easthardware_pms/presentation/router/app_routes.dart';
import 'package:easthardware_pms/presentation/widgets/animated_single_child_scroll_view.dart';
import 'package:easthardware_pms/presentation/widgets/layout/spacing.dart';
import 'package:easthardware_pms/presentation/widgets/text.dart';
import 'package:easthardware_pms/utils/typed_routes.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:provider/provider.dart';
import 'package:scroll_animator/scroll_animator.dart';

class LowerStockedProducts extends StatefulWidget {
  const LowerStockedProducts({super.key});

  @override
  State<LowerStockedProducts> createState() => _LowerStockedProductsState();
}

class _LowerStockedProductsState extends State<LowerStockedProducts> {
  late final GlobalKey _globalKey = GlobalKey();

  late final AnimatedScrollController verticalScrollController;
  late final AnimatedScrollController horizontalScrollController;

  static final Map<String, (int?, Widget Function(Product))> _rowExtents = {
    "Name": (
      4,
      (p) => Text(p.name),
    ),
    "Quantity": (
      2,
      (p) => Text("${p.quantity} ${p.mainUnit}"),
    ),
    "Actions": (
      1,
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

  double? height;

  @override
  void initState() {
    super.initState();
    verticalScrollController = AnimatedScrollController(
      animationFactory: const ChromiumEaseInOut(),
    );
    horizontalScrollController = AnimatedScrollController(
      animationFactory: const ChromiumEaseInOut(),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final renderBox = _globalKey.currentContext?.findRenderObject() as RenderBox?;

      if (renderBox != null) {
        setState(() {
          height = renderBox.size.height;
        });
      }
    });
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
        .where((p) => p.isBelowReorderPoint == true)
        .toList()
      ..sort((a, b) => a.quantity.compareTo(b.quantity));

    final matrix = [
      [
        for (final MapEntry(key: columnName, value: (flex, _)) in _rowExtents.entries)
          if (flex != null)
            Expanded(
              flex: flex,
              child: Text(
                columnName,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            )
          else
            Text(
              columnName,
              style: const TextStyle(fontWeight: FontWeight.w600),
            )
      ],
      for (final product in height == null ? products.take(6) : products) //
        [
          for (final (flex, selector) in _rowExtents.values)
            if (flex != null) Expanded(flex: flex, child: selector(product)) else selector(product)
        ]
    ];

    return Container(
      key: _globalKey,
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
              child: Builder(builder: (context) {
                final widget = Column(
                  children: [
                    for (final row in matrix)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [for (final cell in row) cell],
                      ),
                  ],
                );

                if (height == null) {
                  return widget;
                }

                return ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: height!),
                  child: AnimatedSingleChildScrollView(child: widget),
                );
              }),
            )
        ],
      ),
    );
  }
}
