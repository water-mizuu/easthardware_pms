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
    final (index, orderItem) = Provider.of<IndexedOrderItem>(context, listen: false);
    _controller = TextEditingController(text: orderItem.name ?? '');

    _controller.addListener(() {
      final bloc = context.read<OrderFormBloc>();
      final (currentIndex, currentItem) = Provider.of<IndexedOrderItem>(context, listen: false);
      final newValue = _controller.text;

      if (currentItem.name != newValue) {
        bloc.add(OrderItemUpdatedEvent(
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
