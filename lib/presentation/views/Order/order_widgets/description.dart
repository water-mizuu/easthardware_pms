import 'package:easthardware_pms/presentation/bloc/order/orderform/order_form_bloc.dart';
import 'package:easthardware_pms/presentation/views/Order/create_expense_order_page.dart';
import 'package:easthardware_pms/presentation/views/Order/create_restock_order_page.dart';
import 'package:easthardware_pms/presentation/widgets/ui/form_table_cell.dart';
import 'package:easthardware_pms/presentation/widgets/ui/text_form_boxes.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:provider/provider.dart';

class Description extends StatefulWidget {
  const Description({super.key, required this.isRestock});
  final bool isRestock;

  @override
  State<Description> createState() => _DescriptionState();
}

class _DescriptionState extends State<Description> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();

    if (widget.isRestock) {
      _controller = TextEditingController(text: '');
    } else {
      try {
        final (_, orderItem) = Provider.of<IndexedOrderItem>(context, listen: false);
        _controller = TextEditingController(text: orderItem.description ?? '');
      } catch (_) {
        _controller = TextEditingController(text: '');
      }
    }

    _controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final newValue = _controller.text.trim();
    final bloc = context.read<OrderFormBloc>();

    if (widget.isRestock) {
      try {
        final (index, _) = context.read<IndexedProductId>();
        final currentFormProduct = bloc.state.products![index];

        if (currentFormProduct.description != newValue) {
          bloc.add(ProductUpdatedEvent(currentFormProduct.copyWith(description: newValue), index));
        }
      } catch (_) {
        // Handle error silently
      }
    } else {
      try {
        final (index, currentItem) = Provider.of<IndexedOrderItem>(context, listen: false);

        if (currentItem.description != newValue) {
          bloc.add(OrderItemUpdatedEvent(currentItem.copyWith(description: newValue), index));
        }
      } catch (_) {
        // Handle error silently
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

    if (widget.isRestock) {
      try {
        final (_, productId) = context.watch<IndexedProductId>();
        enabled = productId != null;
        placeholder = 'Sale Description';
      } catch (_) {
        // keep defaults
      }
    }

    return FormTableCell(
      child: TextFormBoxes.ghost(
        controller: _controller,
        enabled: enabled,
        placeholder: placeholder,
      ),
    );
  }
}
