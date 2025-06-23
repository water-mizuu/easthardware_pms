import 'package:easthardware_pms/presentation/bloc/order/orderform/order_form_bloc.dart';
import 'package:easthardware_pms/presentation/models/form_order_item.dart';
import 'package:easthardware_pms/presentation/widgets/ui/form_table_cell.dart';
import 'package:easthardware_pms/presentation/widgets/ui/text_form_boxes.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

// Define the IndexedOrderItem type here to avoid import cycles
typedef IndexedOrderItem = (int, FormOrderItem);

class Quantity extends StatefulWidget {
  const Quantity({super.key});

  @override
  State<Quantity> createState() => QuantityState();
}

class QuantityState extends State<Quantity> {
  late final TextEditingController _controller;
  @override
  void initState() {
    super.initState();
    final (index, orderItem) = Provider.of<IndexedOrderItem>(context, listen: false);
    // Initialize the controller with the current quantity or default to empty string
    _controller = TextEditingController(
      text: orderItem.quantity > 0
          ? (orderItem.quantity % 1 == 0
              ? orderItem.quantity.toInt().toString()
              : orderItem.quantity.toString())
          : '',
    );

    _controller.addListener(() {
      final bloc = context.read<OrderFormBloc>();
      final (currentIndex, currentItem) = Provider.of<IndexedOrderItem>(context, listen: false);
      final newValue = double.tryParse(_controller.text) ?? 0;

      if (currentItem.quantity != newValue) {
        bloc.add(OrderItemUpdatedEvent(
          currentItem.copyWith(
            quantity: newValue,
            amount: newValue * currentItem.rate,
          ),
          currentIndex,
        ));
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final (_, orderItem) = Provider.of<IndexedOrderItem>(context);

    // Update controller if the value changed externally
    String newQuantity = '';
    if (orderItem.quantity > 0) {
      newQuantity = orderItem.quantity % 1 == 0
          ? orderItem.quantity.toInt().toString()
          : orderItem.quantity.toString();
    }

    // Only update if the controller text is different to avoid cursor issues
    if (_controller.text != newQuantity) {
      _controller.text = newQuantity;
    }

    return FormTableCell(
      child: TextFormBoxes.ghost(
        controller: _controller,
        placeholder: '0',
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
        ],
      ),
    );
  }
}
