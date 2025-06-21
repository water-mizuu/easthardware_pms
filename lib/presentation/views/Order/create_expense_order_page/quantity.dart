part of '../create_expense_order_page.dart';

class _Quantity extends StatefulWidget {
  const _Quantity();

  @override
  State<_Quantity> createState() => _QuantityState();
}

class _QuantityState extends State<_Quantity> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    final (index, orderItem) = Provider.of<IndexedOrderItem>(context, listen: false);
    _controller = TextEditingController(
      text: orderItem.quantity % 1 == 0
          ? orderItem.quantity.toInt().toString()
          : orderItem.quantity.toString(),
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
    final newQuantity = orderItem.quantity % 1 == 0
        ? orderItem.quantity.toInt().toString()
        : orderItem.quantity.toString();

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
