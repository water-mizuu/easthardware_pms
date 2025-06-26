import 'package:easthardware_pms/domain/enums/enums.dart';
import 'package:easthardware_pms/presentation/bloc/order/orderform/order_form_bloc.dart';
import 'package:easthardware_pms/presentation/views/order/create_expense_order_page.dart';
import 'package:easthardware_pms/presentation/views/order/create_restock_order_page.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:provider/provider.dart';

class RemoveButton extends StatelessWidget {
  const RemoveButton({super.key});

  @override
  Widget build(BuildContext context) {
    VoidCallback? onPressed;

    final isRestock = context.select((OrderFormBloc b) => b.state.orderType == OrderType.restock);
    if (isRestock) {
      final (index, _) = context.watch<IndexedProductId>();
      onPressed = () {
        context.read<OrderFormBloc>().add(ProductRemovedEvent(index));
      };
    } else {
      final (index, _) = context.watch<IndexedOrderItem>();
      onPressed = () {
        context.read<OrderFormBloc>().add(OrderItemRemovedEvent(index));
      };
    }

    return SizedBox(
      width: 82.0,
      child: Center(
        child: IconButton(
          icon: const Icon(FluentIcons.cancel),
          onPressed: onPressed,
        ),
      ),
    );
  }
}
