import 'package:easthardware_pms/presentation/views/Order/create_expense_order_page.dart';
import 'package:easthardware_pms/presentation/views/Order/create_restock_order_page.dart';
import 'package:easthardware_pms/presentation/widgets/ui/form_table_cell.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:provider/provider.dart';

class Index extends StatelessWidget {
  const Index({super.key, required this.isRestock});
  final bool isRestock;

  @override
  Widget build(BuildContext context) {
    int index;

    try {
      if (isRestock) {
        final (restockIndex, _) = context.watch<IndexedProductId>();
        index = restockIndex;
      } else {
        final (expenseIndex, _) = Provider.of<IndexedOrderItem>(context);
        index = expenseIndex;
      }
    } catch (e) {
      index = 0;
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
