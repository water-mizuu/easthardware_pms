import 'package:easthardware_pms/domain/enums/enums.dart';
import 'package:easthardware_pms/presentation/bloc/inventory/product_list/product_list_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/order/orderform/order_form_bloc.dart';
import 'package:easthardware_pms/presentation/models/form_order_item.dart';
import 'package:easthardware_pms/presentation/widgets/ui/form_table_cell.dart';
import 'package:easthardware_pms/presentation/widgets/ui/text_form_boxes.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

// Define type aliases directly to avoid import cycles
typedef IndexedOrderItem = (int, FormOrderItem);
typedef IndexedProductId = (int, int?);

class Description extends StatefulWidget {
  const Description({super.key});

  @override
  State<Description> createState() => _DescriptionState();
}

class _DescriptionState extends State<Description> {
  late final TextEditingController _controller;
  bool _isRestock = false;
  int? _currentProductId;
  @override
  void initState() {
    super.initState();

    // Initialize the controller, we'll populate it in didChangeDependencies
    _controller = TextEditingController(text: '');
    _controller.addListener(_onTextChanged);

    // Try to set initial description if available
    try {
      final orderFormState = context.read<OrderFormBloc>().state;
      _isRestock = orderFormState.orderType == OrderType.restock;

      // For expense orders, try to get the description from the current item
      if (!_isRestock) {
        final (_, orderItem) = context.read<IndexedOrderItem>();
        if (orderItem.description != null) {
          _controller.text = orderItem.description ?? '';
        }
      }
    } catch (e) {
      // This is fine, we'll set it in didChangeDependencies
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final isRestock = context.watch<OrderFormBloc>().state.orderType == OrderType.restock;
    if (isRestock != _isRestock) {
      _isRestock = isRestock;
      // Only clear text when switching between order types, not on every dependency change
      _controller.text = '';
    }

    // Handle restock orders
    if (_isRestock) {
      final (index, currentProductId) = context.watch<IndexedProductId>();

      if (_currentProductId != currentProductId) {
        // Get the form product from the OrderFormBloc state instead of the default product data
        // This ensures we get the saved description, not the default product description
        final formProduct = context.read<OrderFormBloc>().state.products?[index];

        // If we have a form product and it has a description, use that
        if (formProduct != null) {
          // Log to help debug description loading
          print(
              '[Description] Loading description for ${formProduct.productName}: "${formProduct.description}"');

          // Only if there's no saved description, fall back to the default product description
          if (formProduct.description == null || formProduct.description!.isEmpty) {
            final defaultProduct = (context.read<ProductListBloc>().state.allProducts)
                .where((p) => currentProductId != null && p.id == currentProductId)
                .firstOrNull;

            _controller.text = defaultProduct?.description ?? '';
            print('[Description] Using default product description: "${_controller.text}"');
          } else {
            // Use the saved description from the form product
            _controller.text = formProduct.description ?? '';
          }
        }

        _currentProductId = currentProductId;
      }
    }
    // Handle expense orders - update the controller when the order item changes
    else {
      try {
        final (_, orderItem) = context.watch<IndexedOrderItem>();
        // Only update if different to avoid cursor position issues
        if (orderItem.description != null && _controller.text != orderItem.description) {
          _controller.text = orderItem.description ?? '';
        }
      } catch (e) {
        // IndexedOrderItem might not be available yet
        print('Description widget: $e');
      }
    }
  }

  void _onTextChanged() {
    final value = _controller.text.trim();

    if (_isRestock) {
      final (index, _) = context.read<IndexedProductId>();
      final currentFormProduct = context.read<OrderFormBloc>().state.products![index];

      if (currentFormProduct.description != value) {
        // Log the description change to help with debugging
        print('[Description] Updating description for ${currentFormProduct.productName}:');
        print('[Description] - Old: "${currentFormProduct.description}"');
        print('[Description] - New: "$value"');

        // Create a copy with the updated description to ensure we don't lose other fields
        final updatedProduct = currentFormProduct.copyWith(
          description: value,
          // Make sure to keep these important fields
          productId: currentFormProduct.productId,
          productName: currentFormProduct.productName,
          quantity: currentFormProduct.quantity,
          rate: currentFormProduct.rate,
          unit: currentFormProduct.unit,
          unitId: currentFormProduct.unitId,
          conversionFactor: currentFormProduct.conversionFactor,
          amount: currentFormProduct.amount,
        );

        // Update the product with our updated version
        context //
            .read<OrderFormBloc>()
            .add(ProductUpdatedEvent(updatedProduct, index));
      }
    } else {
      final (index, currentItem) = context.read<IndexedOrderItem>();

      if (currentItem.description != value) {
        context
            .read<OrderFormBloc>()
            .add(OrderItemUpdatedEvent(currentItem.copyWith(description: value), index));
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var enabled = true;
    var placeholder = 'Description';

    // Special handling for restock orders
    if (_isRestock) {
      final (_, productId) = context.watch<IndexedProductId>();
      enabled = productId != null;
      placeholder = 'Sale Description';
    }
    // Special handling for expense orders
    else {
      try {
        // For expense orders, always enable the description field
        final (_, orderItem) = context.watch<IndexedOrderItem>();
        // If we have a name, use it in the placeholder for better context
        if (orderItem.name != null && orderItem.name!.isNotEmpty) {
          placeholder = 'Description';
        }
      } catch (e) {
        // IndexedOrderItem might not be available yet
      }
    }

    return FormTableCell(
      child: TextFormBoxes.ghost(
        inputFormatters: [
          LengthLimitingTextInputFormatter(120),
          FilteringTextInputFormatter.deny(RegExp(r'[\n\r]')),
        ],
        controller: _controller,
        enabled: enabled,
        placeholder: placeholder,
      ),
    );
  }
}
