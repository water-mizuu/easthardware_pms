part of '../create_restock_order_page.dart';

class _RemoveButton extends StatelessWidget {
  const _RemoveButton();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 82.0,
      child: Center(
        child: IconButton(
          icon: const Icon(FluentIcons.cancel),
          onPressed: () {
            final (index, _) = context.read<IndexedProductId>();

            context.read<OrderFormBloc>().add(ProductRemovedEvent(index));
          },
        ),
      ),
    );
  }
}
