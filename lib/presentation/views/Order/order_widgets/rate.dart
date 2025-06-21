import 'package:easthardware_pms/presentation/bloc/order/orderform/order_form_bloc.dart';
import 'package:easthardware_pms/presentation/views/Order/create_expense_order_page.dart';
import 'package:easthardware_pms/presentation/views/Order/create_restock_order_page.dart';
import 'package:easthardware_pms/presentation/widgets/ui/form_table_cell.dart';
import 'package:easthardware_pms/presentation/widgets/ui/text_form_boxes.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class Rate extends StatefulWidget {
  const Rate({super.key, required this.isRestock});
  final bool isRestock;

  @override
  State<Rate> createState() => _RateState();
}

class _RateState extends State<Rate> {
  late final TextEditingController _controller;
  late int? _currentProductId;

  @override
  void initState() {
    super.initState();

    if (widget.isRestock) {
      _currentProductId = null;
      _controller = TextEditingController();
    } else {
      try {
        final (_, orderItem) = Provider.of<IndexedOrderItem>(context, listen: false);
        _controller = TextEditingController(
          text: orderItem.rate % 1 == 0
              ? orderItem.rate.toInt().toString()
              : orderItem.rate.toString(),
        );
      } catch (_) {
        _controller = TextEditingController();
      }
    }

    _controller.addListener(_onRateChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (widget.isRestock) {
      _handleRestockContextChange();
    } else {
      _handleExpenseContextChange();
    }
  }

  void _handleRestockContextChange() {
    try {
      final (index, currentProductId) = context.watch<IndexedProductId>();
      if (_currentProductId != currentProductId) {
        _currentProductId = currentProductId;
        final currentFormProduct = context.read<OrderFormBloc>().state.products![index];
        _updateControllerWithRate(currentFormProduct.rate);
      }
    } catch (_) {}
  }

  void _handleExpenseContextChange() {
    try {
      final (_, orderItem) = Provider.of<IndexedOrderItem>(context);
      final newRate =
          orderItem.rate % 1 == 0 ? orderItem.rate.toInt().toString() : orderItem.rate.toString();

      if (_controller.text != newRate) {
        _controller.text = newRate;
      }
    } catch (_) {}
  }

  void _onRateChanged() {
    final newRate = double.tryParse(_controller.text) ?? 0;

    if (widget.isRestock) {
      _handleRestockRateChange(newRate);
    } else {
      _handleExpenseRateChange(newRate);
    }
  }

  void _handleRestockRateChange(double newRate) {
    try {
      final (index, _) = context.read<IndexedProductId>();
      final currentFormProduct = context.read<OrderFormBloc>().state.products![index];

      if (currentFormProduct.rate != newRate) {
        context.read<OrderFormBloc>().add(ProductUpdatedEvent(
              currentFormProduct.copyWith(
                rate: newRate,
                amount: currentFormProduct.quantity * newRate,
              ),
              index,
            ));
      }
    } catch (_) {}
  }

  void _handleExpenseRateChange(double newRate) {
    try {
      final bloc = context.read<OrderFormBloc>();
      final (currentIndex, currentItem) = Provider.of<IndexedOrderItem>(context, listen: false);

      if (currentItem.rate != newRate) {
        bloc.add(OrderItemUpdatedEvent(
          currentItem.copyWith(
            rate: newRate,
            amount: newRate * currentItem.quantity,
          ),
          currentIndex,
        ));
      }
    } catch (_) {}
  }

  void _updateControllerWithRate(double rate) {
    final rateRepresentation = rate % 1 == 0 ? rate.toInt().toString() : rate.toString();

    if (_controller.text != rateRepresentation) {
      _controller.text = rateRepresentation;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final placeholder = widget.isRestock ? '0.0' : '0.00';

    return FormTableCell(
      child: TextFormBoxes.ghost(
        controller: _controller,
        placeholder: placeholder,
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))],
      ),
    );
  }
}
