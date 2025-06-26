import 'package:easthardware_pms/domain/enums/enums.dart';
import 'package:easthardware_pms/presentation/bloc/order/orderform/order_form_bloc.dart';
import 'package:easthardware_pms/presentation/views/order/create_expense_order_page.dart';
import 'package:easthardware_pms/presentation/views/order/create_restock_order_page.dart';
import 'package:easthardware_pms/presentation/widgets/ui/form_table_cell.dart';
import 'package:easthardware_pms/presentation/widgets/ui/text_form_boxes.dart';
import 'package:easthardware_pms/utils/number_string.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class Rate extends StatefulWidget {
  const Rate({super.key});

  @override
  State<Rate> createState() => _RateState();
}

class _RateState extends State<Rate> {
  late final TextEditingController _controller;

  int? _currentProductId;
  bool _isRestock = false;

  @override
  void initState() {
    super.initState();

    _controller = TextEditingController();
    _controller.addListener(_onControllerChange);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final isRestock = context.watch<OrderFormBloc>().state.orderType == OrderType.restock;
    if (isRestock != _isRestock) {
      _isRestock = isRestock;
    }

    if (_isRestock) {
      final (index, currentProductId) = context.watch<IndexedProductId>();
      final currentFormProduct = context.watch<OrderFormBloc>().state.products![index];

      if (_currentProductId != currentProductId) {
        _currentProductId = currentProductId;
        _controller.text = currentFormProduct.rate.toNumberString();
      }
    } else {
      final (_, orderItem) = context.watch<IndexedOrderItem>();
      final newRate = orderItem.rate.toNumberString();

      if (_controller.text != newRate) {
        _controller.text = newRate;
      }
    }
  }

  void _onControllerChange() {
    final newRate = double.tryParse(_controller.text) ?? 0;

    if (_isRestock) {
      final (index, _) = context.read<IndexedProductId>();
      // Always get the latest state to ensure we have the most up-to-date product data
      final currentFormProduct = context.read<OrderFormBloc>().state.products![index];

      if (currentFormProduct.rate != newRate) {
        // Use the current quantity from the product to ensure we have the latest quantity
        final currentQuantity = currentFormProduct.quantity;
        context //
            .read<OrderFormBloc>()
            .add(ProductUpdatedEvent(
              currentFormProduct.copyWith(
                rate: newRate,
                amount: currentQuantity * newRate,
              ),
              index,
            ));
      }
    } else {
      final (index, currentItem) = context.read<IndexedOrderItem>();

      if (currentItem.rate != newRate) {
        context //
            .read<OrderFormBloc>()
            .add(OrderItemUpdatedEvent(
              currentItem.copyWith(
                rate: newRate,
                amount: newRate * currentItem.quantity,
              ),
              index,
            ));
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
    final placeholder = _isRestock ? '0.0' : '0.00';

    return FormTableCell(
      child: TextFormBoxes.ghost(
        controller: _controller,
        placeholder: placeholder,
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))],
      ),
    );
  }
}
