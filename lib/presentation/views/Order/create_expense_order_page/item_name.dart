part of '../create_expense_order_page.dart';

class _ItemName extends StatefulWidget {
  const _ItemName();

  @override
  State<_ItemName> createState() => _ItemNameState();
}

class _ItemNameState extends State<_ItemName> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();

    final (index, orderItem) = context.read<IndexedOrderItem>();
    _controller = TextEditingController(text: orderItem.name ?? '');

    _controller.addListener(() {
      final (currentIndex, currentItem) = context.read<IndexedOrderItem>();
      final newValue = _controller.text;

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
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FormTableCell(
      child: TextFormBoxes.ghost(
        controller: _controller,
        placeholder: 'Order Item',
      ),
    );
  }
}
