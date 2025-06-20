part of '../create_restock_order_page.dart';

class _Amount extends StatelessWidget {
  const _Amount();

  @override
  Widget build(BuildContext context) {
    final (index, _) = context.watch<IndexedProductId>();
    final currentFormProduct = context.watch<OrderFormBloc>().state.products![index];

    return FormTableCell(
      child: TextFormBoxes.ghost(
        enabled: false,
        placeholder: CurrencyFormatter.full(currentFormProduct.amount),
      ),
    );
  }
}
