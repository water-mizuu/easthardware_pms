import 'package:easthardware_pms/presentation/bloc/order/orderform/order_form_bloc.dart';
import 'package:easthardware_pms/presentation/models/form_order_item.dart';
import 'package:easthardware_pms/presentation/widgets/ui/form_table_cell.dart';
import 'package:easthardware_pms/presentation/widgets/ui/text_form_boxes.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';

// Define the IndexedOrderItem type here to avoid import cycles
typedef IndexedOrderItem = (int, FormOrderItem);

class ItemName extends StatefulWidget {
  const ItemName({super.key});

  @override
  State<ItemName> createState() => ItemNameState();
}

class ItemNameState extends State<ItemName> {
  late final TextEditingController _itemNameController;

  @override
  void initState() {
    super.initState();

    final (index, orderItem) = context.read<IndexedOrderItem>();
    _itemNameController = TextEditingController(text: orderItem.name ?? '');

    _itemNameController.addListener(() {
      final (currentIndex, currentItem) = context.read<IndexedOrderItem>();
      final newValue = _itemNameController.text;

      if (currentItem.name != newValue) {
        context //
            .read<OrderFormBloc>()
            .add(OrderItemUpdatedEvent(
              currentItem.copyWith(name: newValue),
              currentIndex,
            ));
      }
    });
  }

  @override
  void dispose() {
    _itemNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Watch for changes in the order item and update the controller if needed
    final (_, orderItem) = context.watch<IndexedOrderItem>();

    // Update controller if the value changed externally (e.g., when loading an existing order)
    if (_itemNameController.text != (orderItem.name ?? '')) {
      _itemNameController.text = orderItem.name ?? '';
    }

    return FormTableCell(
      child: TextFormBoxes.ghost(
        inputFormatters: [
          FilteringTextInputFormatter.deny(RegExp(r'[\n\r]')),
          LengthLimitingTextInputFormatter(100),
        ],
        controller: _itemNameController,
        placeholder: 'Order Item',
      ),
    );
  }
}
