part of '../create_restock_order_page.dart';

class _QuantityAndUnit extends StatefulWidget {
  const _QuantityAndUnit();

  @override
  State<_QuantityAndUnit> createState() => _QuantityAndUnitState();
}

class _QuantityAndUnitState extends State<_QuantityAndUnit> {
  late final TextEditingController _quantityController;
  late int? _currentProductId;

  @override
  void initState() {
    super.initState();

    _quantityController = TextEditingController();
    _currentProductId = null;

    _quantityController.addListener(() {
      /// Synchronize the quantity in the controller and the current form product.
      final (index, currentProductId) = context.read<IndexedProductId>();
      final currentFormProduct = (context.read<OrderFormBloc>().state.products!)
          .firstWhere((p) => p.productId == currentProductId);
      final newQuantity = double.tryParse(_quantityController.text) ?? 0;

      if (currentFormProduct.quantity != newQuantity) {
        context //
            .read<OrderFormBloc>()
            .add(ProductUpdatedEvent(
              currentFormProduct.copyWith(
                quantity: newQuantity,
                amount: newQuantity * currentFormProduct.rate,
              ),
              index,
            ));
        _updateQuantityControllerWithQuantity(newQuantity);
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final (_, currentProductId) = context.watch<IndexedProductId>();
    if (_currentProductId == currentProductId) {
      final currentFormProduct = (context.read<OrderFormBloc>().state.products!)
          .where((p) => p.productId == currentProductId)
          .firstOrNull;

      _updateQuantityControllerWithQuantity(currentFormProduct?.quantity ?? 0);
    }
  }

  void _updateQuantityControllerWithQuantity(double quantity) {
    final quantityRepresentation = quantity % 1 == 0 //
        ? quantity.toInt().toString()
        : quantity.toString();

    if (_quantityController.text != quantityRepresentation) {
      _quantityController.text = quantityRepresentation;
    }
  }

  @override
  Widget build(BuildContext context) {
    /// Get the current form product ID.
    final (index, currentProductId) = context.watch<IndexedProductId>();

    printBoxed("Current form product ID: $currentProductId", "QuantityAndUnit");

    /// [currentProduct] is late as there is a chance that the variable is not used.
    ///   This happens when the product is not selected yet.
    final currentProduct = (context.read<ProductListBloc>().state.allProducts)
        .where((p) => p.id == currentProductId)
        .firstOrNull;

    printBoxed(
      "Current product: \n${const JsonEncoder.withIndent("  ").convert(currentProduct?.toMap())}",
      "QuantityAndUnit",
    );

    return FormTableCell(
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 1,
              child: TextFormBoxes.ghost(
                controller: _quantityController,
                placeholder: '0',
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                ],
              ),
            ),
            if (currentProduct != null)
              Expanded(
                flex: 2,
                child: Builder(builder: (context) {
                  final selectedUnit = context.watch<OrderFormBloc>().state.products![index].unit;

                  return DropDownButton(
                    items: [
                      MenuFlyoutItem(
                          text: Text(currentProduct.mainUnit),
                          selected: selectedUnit == currentProduct.mainUnit,
                          onPressed: () {
                            context //
                                .read<OrderFormBloc>()
                                .add(ProductUpdatedEvent(
                                  context.read<OrderFormBloc>().state.products![index].copyWith(
                                        unitId: null,
                                        rate: currentProduct.orderCost,
                                        unit: currentProduct.mainUnit,
                                        conversionFactor: 1.0,
                                      ),
                                  index,
                                ));
                          }),
                      for (final unit in context
                          .read<UnitListBloc>()
                          .state
                          .units
                          .where((u) => u.productId == currentProductId))
                        MenuFlyoutItem(
                          text: Text(unit.name),
                          selected: selectedUnit == unit.name,
                          onPressed: () {
                            context.read<OrderFormBloc>().add(ProductUpdatedEvent(
                                  context.read<OrderFormBloc>().state.products![index].copyWith(
                                        unitId: unit.id,
                                        rate: currentProduct.orderCost *
                                            (unit.mainQuantity / unit.unitQuantity),
                                        unit: unit.name,
                                        conversionFactor: unit.mainQuantity / unit.unitQuantity,
                                      ),
                                  index,
                                ));
                          },
                        ),
                    ],
                    buttonBuilder: (context, onOpen) {
                      return Button(
                        style: ButtonStyle(
                          padding: const WidgetStatePropertyAll(
                            EdgeInsetsDirectional.fromSTEB(0, 5, 0, 6),
                          ),
                          shape: WidgetStatePropertyAll(
                            RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4.0),
                              side: const BorderSide(color: Colors.transparent),
                            ),
                          ),
                        ),
                        onPressed: onOpen,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(context.read<OrderFormBloc>().state.products![index].unit),
                            Spacing.h12,
                            const Icon(FluentIcons.chevron_down),
                          ],
                        ),
                      );
                    },
                  );
                }),
              ),
          ],
        ),
      ),
    );
  }
}
