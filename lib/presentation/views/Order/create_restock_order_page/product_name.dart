import 'package:easthardware_pms/presentation/bloc/inventory/product_list/product_list_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/order/orderform/order_form_bloc.dart';
import 'package:easthardware_pms/presentation/views/Order/create_restock_order_page.dart';
import 'package:easthardware_pms/presentation/widgets/auto_auto_suggest_box.dart';
import 'package:easthardware_pms/presentation/widgets/ui/decorations.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ProductName extends StatefulWidget {
  const ProductName({super.key});

  @override
  State<ProductName> createState() => _ProductNameState();
}

class _ProductNameState extends State<ProductName> {
  late final TextEditingController _productNameController;
  late int? _currentProductId;

  @override
  void initState() {
    super.initState();

    /// Initialize the product name controller.
    _productNameController = TextEditingController();
    _currentProductId = null;

    _productNameController.addListener(() {
      /// Get the index of this row.
      final (index, _) = context.read<IndexedProductId>();

      /// Get the form product saved in the row.
      final currentFormProduct = context.read<OrderFormBloc>().state.products![index];

      /// Get the new name.
      final newName = _productNameController.text.trim();

      /// If the new name does not match the current product name,
      ///   update the product in the bloc.
      ///
      /// WARN: This might be non-performant if the product list is large,
      ///   as it searches for the product by name.
      ///
      ///  Consider using a prefix tree.
      if (currentFormProduct.productName != newName) {
        final currentProduct = (context.read<ProductListBloc>().state.allProducts)
            .where((p) => p.name == newName)
            .firstOrNull;

        context //
            .read<OrderFormBloc>()
            .add(
              ProductUpdatedEvent(
                currentFormProduct.copyWith(
                  productName: newName,
                  productId: currentProduct?.id,
                  unit: currentProduct?.mainUnit ?? '',
                  rate: currentProduct == null ? 0 : currentProduct.orderCost,
                ),
                index,
              ),
            );

        _updateProductNameControllerWithProductName(newName);
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    /// Read the current product from the IndexedFormProduct context.
    ///
    /// NOTE: This is not done in the didUpdateDependencies method as we don't want
    ///   it to react to changes in the IndexedFormProduct context.
    /// Why? Because we are the ones updating the product name in the bloc.
    final (index, currentProductId) = context.watch<IndexedProductId>();
    if (currentProductId != _currentProductId) {
      _currentProductId = currentProductId;

      final currentProduct = (context.read<OrderFormBloc>().state.products!)
          .where((p) => p.productId == currentProductId)
          .firstOrNull;

      /// Update the product name controller with the current product name.
      if (currentProduct?.productName case final productName?) {
        _updateProductNameControllerWithProductName(productName);
      }
    }
  }

  @override
  void dispose() {
    _productNameController.dispose();

    super.dispose();
  }

  void _updateProductNameControllerWithProductName(String productName) {
    if (_productNameController.text != productName) {
      _productNameController.text = productName;
    }
  }

  @override
  Widget build(BuildContext context) {
    final products = context.select((ProductListBloc b) => b.state.allProducts);

    return Container(
      decoration: const BoxDecoration(
        border: Border(
          right: BorderSide(
            width: 0.5,
            color: Colors.transparent,
          ),
        ),
      ),
      child: AutoAutoSuggestBox.form(
        controller: _productNameController,
        decoration: BoxDecorations.ghost,
        foregroundDecoration: BoxDecorations.ghost,
        items: [
          for (final product in products)
            AutoSuggestBoxItem(
              value: product,
              label: product.name,
            ),
        ],

        /// We do nothing on select, as this should be handled by the change listener.
        ///   Additional logic here makes it brittle.
        onSelected: (_) {},
        placeholder: 'Select Product',
      ),
    );
  }
}
