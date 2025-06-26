import 'package:easthardware_pms/domain/enums/enums.dart';
import 'package:easthardware_pms/presentation/bloc/order/orderform/order_form_bloc.dart';
import 'package:easthardware_pms/presentation/views/order/create_expense_order_page.dart';
import 'package:easthardware_pms/presentation/views/order/create_restock_order_page.dart';
import 'package:easthardware_pms/presentation/widgets/ui/form_table_cell.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:provider/provider.dart';

class Index extends StatelessWidget {
  const Index({super.key});

  @override
  Widget build(BuildContext context) {
    int index;

    final isRestock = context.select((OrderFormBloc b) => b.state.orderType == OrderType.restock);
    if (isRestock) {
      final (restockIndex, _) = context.watch<IndexedProductId>();
      index = restockIndex;
    } else {
      final (expenseIndex, _) = context.watch<IndexedOrderItem>();
      index = expenseIndex;
    }

    return FormTableCell(
      child: SizedBox(
        height: 32.0,
        width: 32.0,
        child: Center(
          child: Text('${index + 1}'),
        ),
      ),
    );
  }
}
