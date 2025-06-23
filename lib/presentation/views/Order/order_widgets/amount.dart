import 'package:easthardware_pms/domain/enums/enums.dart';
import 'package:easthardware_pms/presentation/bloc/order/orderform/order_form_bloc.dart';
import 'package:easthardware_pms/presentation/views/Order/create_expense_order_page.dart';
import 'package:easthardware_pms/presentation/views/Order/create_restock_order_page.dart';
import 'package:easthardware_pms/presentation/widgets/helper/currency_formatter.dart';
import 'package:easthardware_pms/presentation/widgets/ui/form_table_cell.dart';
import 'package:easthardware_pms/presentation/widgets/ui/text_form_boxes.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:provider/provider.dart';

class Amount extends StatelessWidget {
  const Amount({super.key});

  @override
  Widget build(BuildContext context) {
    final isRestock = context.select((OrderFormBloc b) => b.state.orderType == OrderType.restock);
    if (isRestock) {
      return Builder(builder: (context) {
        final (index, _) = context.watch<IndexedProductId>();
        final currentFormProduct = context.watch<OrderFormBloc>().state.products![index];
        final calculatedAmount = currentFormProduct.quantity * currentFormProduct.rate;
        final displayText = CurrencyFormatter.full(calculatedAmount);

        return FormTableCell(
          child: TextFormBoxes.ghost(
            enabled: false,
            placeholder: displayText.isEmpty ? '0.00' : displayText,
          ),
        );
      });
    } else {
      return Builder(builder: (context) {
        final (_, orderItem) = context.watch<IndexedOrderItem>();
        final displayAmount = CurrencyFormatter.full(orderItem.amount);

        return FormTableCell(
          child: TextFormBoxes.ghost(
            enabled: false,
            placeholder: displayAmount.isEmpty ? '0.00' : displayAmount,
          ),
        );
      });
    }
  }
}
