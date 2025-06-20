part of '../create_restock_order_page.dart';

class _Rate extends StatefulWidget {
  const _Rate();

  @override
  State<_Rate> createState() => _RateState();
}

class _RateState extends State<_Rate> {
  late int? _currentProductId;
  late final TextEditingController _rateController;

  @override
  void initState() {
    super.initState();

    _currentProductId = null;

    /// Initialize the rate controller.
    _rateController = TextEditingController()
      ..addListener(() {
        /// Synchronize the rate in the controller and the current form product.
        final (index, _) = context.read<IndexedProductId>();
        final currentFormProduct = context.read<OrderFormBloc>().state.products![index];

        final rate = double.tryParse(_rateController.text) ?? 0;
        if (currentFormProduct.rate != rate) {
          context //
              .read<OrderFormBloc>()
              .add(ProductUpdatedEvent(
                currentFormProduct.copyWith(
                  rate: rate,
                  amount: currentFormProduct.quantity * rate,
                ),
                index,
              ));
        }
      });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    /// Watch the indexed form product ID to update the rate controller
    ///   with the current form product's rate.
    ///
    /// This is done so that when the form product ID changes,
    ///   the rate controller is updated with the new form product's rate.
    final (index, currentProductId) = context.watch<IndexedProductId>();
    if (_currentProductId != currentProductId) {
      _currentProductId = currentProductId;

      final currentFormProduct = context.read<OrderFormBloc>().state.products![index];

      _updateRateControllerWithRate(currentFormProduct.rate);
    }
  }

  void _updateRateControllerWithRate(double rate) {
    final rateRepresentation = rate % 1 == 0 //
        ? rate.toInt().toString()
        : rate.toString();

    if (_rateController.text != rateRepresentation) {
      _rateController.text = rateRepresentation;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FormTableCell(
      child: TextFormBoxes.ghost(
        controller: _rateController,
        placeholder: '0.0',
        // enabled: false,
      ),
    );
  }
}
