part of '../create_restock_order_page.dart';

class _Index extends StatelessWidget {
  const _Index();

  @override
  Widget build(BuildContext context) {
    final (index, _) = context.watch<IndexedProductId>();

    return FormTableCell(
      child: SizedBox(
        height: 32.0,
        width: 32.0,
        child: Center(
          child: Text((index + 1).toString()),
        ),
      ),
    );
  }
}
