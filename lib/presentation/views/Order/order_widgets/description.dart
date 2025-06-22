import 'package:easthardware_pms/domain/enums/enums.dart';
import 'package:easthardware_pms/presentation/bloc/inventory/product_list/product_list_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/order/orderform/order_form_bloc.dart';
import 'package:easthardware_pms/presentation/views/Order/create_expense_order_page.dart';
import 'package:easthardware_pms/presentation/views/Order/create_restock_order_page.dart';
import 'package:easthardware_pms/presentation/widgets/ui/form_table_cell.dart';
import 'package:easthardware_pms/presentation/widgets/ui/text_form_boxes.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:provider/provider.dart';

class Description extends StatefulWidget {
  const Description({super.key});

  @override
  State<Description> createState() => _DescriptionState();
}

class _DescriptionState extends State<Description> {
  late final TextEditingController _controller;
  bool _isRestock = false;
  int? _currentProductId;

  @override
  void initState() {
    super.initState();

    _controller = TextEditingController(text: '');
    _controller.addListener(_onTextChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final isRestock = context.watch<OrderFormBloc>().state.orderType == OrderType.restock;
    if (isRestock != _isRestock) {
      _isRestock = isRestock;

      _controller.text = '';
    }

    if (_isRestock) {
      final (_, currentProductId) = context.watch<IndexedProductId>();

      if (_currentProductId != currentProductId) {
        final currentProduct = (context.read<ProductListBloc>().state.allProducts)
            .where((p) => currentProductId != null && p.id == currentProductId)
            .firstOrNull;

        _currentProductId = currentProductId;
        _controller.text = currentProduct?.description ?? '';
      }
    }
  }

  void _onTextChanged() {
    final value = _controller.text.trim();

    if (_isRestock) {
      final (index, _) = context.read<IndexedProductId>();
      final currentFormProduct = context.read<OrderFormBloc>().state.products![index];

      if (currentFormProduct.description != value) {
        context
            .read<OrderFormBloc>()
            .add(ProductUpdatedEvent(currentFormProduct.copyWith(description: value), index));
      }
    } else {
      final (index, currentItem) = context.read<IndexedOrderItem>();

      if (currentItem.description != value) {
        context
            .read<OrderFormBloc>()
            .add(OrderItemUpdatedEvent(currentItem.copyWith(description: value), index));
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
    var enabled = true;
    var placeholder = 'Description';

    if (_isRestock) {
      final (_, productId) = context.watch<IndexedProductId>();

      enabled = productId != null;
      placeholder = 'Sale Description';
    }

    return FormTableCell(
      child: TextFormBoxes.ghost(
        controller: _controller,
        enabled: enabled,
        placeholder: placeholder,
      ),
    );
  }
}
