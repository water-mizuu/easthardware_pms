import 'package:easthardware_pms/domain/models/product.dart';
import 'package:easthardware_pms/presentation/widgets/helper/currency_formatter.dart';
import 'package:easthardware_pms/presentation/widgets/ui/styles.dart';
import 'package:flutter/material.dart' show DataCell, DataRow, DataTableSource, Text;

class ArchivedProductDataSource extends DataTableSource {
  ArchivedProductDataSource({
    required this.products,
  });

  final List<Product> products;

  @override
  DataRow? getRow(int index) {
    final product = products[index];

    return DataRow(cells: [
      DataCell(Text(product.id.toString(), style: TextStyles.body)),
      DataCell(Text(product.sku, style: TextStyles.body)),
      DataCell(Text(product.name, style: TextStyles.body)),
      DataCell(Text(product.categoryName ?? '', style: TextStyles.body)),
      DataCell(Text(CurrencyFormatter.full(product.salePrice), style: TextStyles.body)),
    ]);
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => products.length;

  @override
  int get selectedRowCount => 0;
}
