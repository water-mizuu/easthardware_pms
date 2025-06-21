part of '../create_restock_order_page.dart';

class _Description extends StatefulWidget {
  const _Description();

  @override
  State<_Description> createState() => _DescriptionState();
}

class _DescriptionState extends State<_Description> {
  late final TextEditingController _descriptionController;
  late int? _currentProductId;

  @override
  void initState() {
    super.initState();

    _descriptionController = TextEditingController(text: '');
    _descriptionController.addListener(() {
      final (index, currentProductId) = context.read<IndexedProductId>();
      final currentFormProduct = context.read<OrderFormBloc>().state.products![index];

      final newValue = _descriptionController.text.trim();
      if (currentFormProduct.description != newValue) {
        context
            .read<OrderFormBloc>() //
            .add(ProductUpdatedEvent(currentFormProduct.copyWith(description: newValue), index));
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final (index, currentProductId) = context.watch<IndexedProductId>();
    if (_currentProductId != currentProductId) {
      _currentProductId = currentProductId;
      final currentProduct = context
          .read<ProductListBloc>()
          .state
          .allProducts //
          .firstWhere((p) => p.id == currentProductId);

      _descriptionController.text = currentProduct.description ?? '';
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final (index, currentProductId) = context.watch<IndexedProductId>();

    return FormTableCell(
      child: TextFormBoxes.ghost(
        controller: _descriptionController,
        enabled: currentProductId != null,
        placeholder: 'Sale Description',
      ),
    );
  }
}
