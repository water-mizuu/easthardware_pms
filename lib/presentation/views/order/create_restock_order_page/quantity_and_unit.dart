import 'package:easthardware_pms/presentation/bloc/inventory/product_list/product_list_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/order/orderform/order_form_bloc.dart';
import 'package:easthardware_pms/presentation/views/order/create_restock_order_page.dart';
import 'package:easthardware_pms/presentation/widgets/ui/form_table_cell.dart';
import 'package:easthardware_pms/presentation/widgets/ui/text_form_boxes.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class QuantityAndUnit extends StatefulWidget {
  const QuantityAndUnit({super.key});

  @override
  State<QuantityAndUnit> createState() => _QuantityAndUnitState();
}

class _QuantityAndUnitState extends State<QuantityAndUnit> {
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
      // Always get the latest state to ensure we have the most up-to-date product data
      final currentFormProduct = (context.read<OrderFormBloc>().state.products!)
          .firstWhere((p) => p.productId == currentProductId);
      final newQuantity = int.tryParse(_quantityController.text) ?? 0;

      if (currentFormProduct.quantity != newQuantity) {
        // Use the current rate from the product to ensure we have the latest rate
        final currentRate = currentFormProduct.rate;
        context //
            .read<OrderFormBloc>()
            .add(ProductUpdatedEvent(
              currentFormProduct.copyWith(
                quantity: newQuantity,
                amount: newQuantity * currentRate,
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

    final (index, currentProductId) = context.watch<IndexedProductId>();

    // Check if product ID is changed or it's the first time loading
    if (_currentProductId != currentProductId) {
      _currentProductId = currentProductId;

      // Clear the controller if the product was removed (currentProductId is null)
      if (currentProductId == null) {
        _quantityController.clear();
        return;
      }
    }

    // Always check for the current form product and update quantity controller
    if (currentProductId != null) {
      // Find the form product by product ID
      final products = context.read<OrderFormBloc>().state.products!;
      final currentFormProduct = products.where((p) => p.productId == currentProductId).firstOrNull;

      // Update the quantity
      if (currentFormProduct != null) {
        _updateQuantityControllerWithQuantity(currentFormProduct.quantity);

        // Always ensure we're using the main unit for restock orders
        final currentProduct = context
            .read<ProductListBloc>()
            .state
            .allProducts
            .where((p) => p.id == currentProductId)
            .firstOrNull;

        if (currentProduct != null && currentFormProduct.unit != currentProduct.mainUnit) {
          // Always update to use the main unit
          context.read<OrderFormBloc>().add(ProductUpdatedEvent(
                currentFormProduct.copyWith(
                  unitId: null,
                  rate: currentProduct.orderCost,
                  unit: currentProduct.mainUnit,
                  conversionFactor: 1.0,
                ),
                index,
              ));
        }
      }
    }
  }

  void _updateQuantityControllerWithQuantity(int quantity) {
    if (_quantityController.text != quantity.toString()) {
      _quantityController.text = quantity.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    /// Get the current form product ID.
    final (index, currentProductId) = context.watch<IndexedProductId>();

    /// [currentProduct] is late as there is a chance that the variable is not used.
    ///   This happens when the product is not selected yet.
    final currentProduct = (context.read<ProductListBloc>().state.allProducts)
        .where((p) => p.id == currentProductId)
        .firstOrNull;

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
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(currentProduct.mainUnit),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
