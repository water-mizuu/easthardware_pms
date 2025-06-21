import 'package:easthardware_pms/presentation/bloc/order/orderform/order_form_bloc.dart';
import 'package:easthardware_pms/presentation/views/Order/create_expense_order_page.dart';
import 'package:easthardware_pms/presentation/views/Order/create_restock_order_page.dart';
import 'package:easthardware_pms/presentation/widgets/helper/currency_formatter.dart';
import 'package:easthardware_pms/presentation/widgets/ui/form_table_cell.dart';
import 'package:easthardware_pms/presentation/widgets/ui/text_form_boxes.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:provider/provider.dart';

class Amount extends StatelessWidget {
  const Amount({super.key, required this.isRestock});
  final bool isRestock;

  @override
  Widget build(BuildContext context) {
    var displayText = '';
    var placeholder = '0.00';

    try {
      if (isRestock) {
        final (index, _) = context.watch<IndexedProductId>();
        final currentFormProduct = context.watch<OrderFormBloc>().state.products![index];
        displayText = CurrencyFormatter.full(currentFormProduct.amount);
        placeholder = displayText;
      } else {
        final (_, orderItem) = context.watch<IndexedOrderItem>();
        displayText = orderItem.amount % 1 == 0
            ? orderItem.amount.toInt().toString()
            : orderItem.amount.toString();
      }
    } catch (_) {
      // fallback values already assigned
    }

    return FormTableCell(
      child: TextFormBoxes.ghost(
        enabled: false,
        placeholder: displayText.isEmpty ? placeholder : displayText,
      ),
    );
  }
}
