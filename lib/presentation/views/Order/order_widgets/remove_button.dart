import 'package:easthardware_pms/presentation/bloc/order/orderform/order_form_bloc.dart';
import 'package:easthardware_pms/presentation/views/Order/create_expense_order_page.dart';
import 'package:easthardware_pms/presentation/views/Order/create_restock_order_page.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:provider/provider.dart';

class RemoveButton extends StatelessWidget {
  final bool isRestock;

  const RemoveButton({super.key, required this.isRestock});

  @override
  Widget build(BuildContext context) {
    var shouldShow = true;
    VoidCallback? onPressed;

    if (isRestock) {
      final (index, _) = context.read<IndexedProductId>();
      onPressed = () {
        context.read<OrderFormBloc>().add(ProductRemovedEvent(index));
      };
    } else {
      final (index, _) = Provider.of<IndexedOrderItem>(context);
      shouldShow = index > 0;
      onPressed = () {
        context.read<OrderFormBloc>().add(OrderItemRemovedEvent(index));
      };
    }

    return SizedBox(
      width: 82.0,
      child: shouldShow
          ? Center(
              child: IconButton(
                icon: const Icon(FluentIcons.cancel),
                onPressed: onPressed,
              ),
            )
          : null,
    );
  }
}
