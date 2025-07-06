import 'package:easthardware_pms/domain/enums/enums.dart';
import 'package:easthardware_pms/domain/models/product.dart';
import 'package:easthardware_pms/presentation/bloc/inventory/product_list/product_list_bloc.dart';
import 'package:easthardware_pms/presentation/views/inventory/product_information_content_dialog.dart';
import 'package:easthardware_pms/presentation/widgets/helper/currency_formatter.dart';
import 'package:easthardware_pms/presentation/widgets/ui/styles.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' show DataCell, DataRow, DataTableSource, Text;
import 'package:flutter_bloc/flutter_bloc.dart';

class ArchivedProductDataSource extends DataTableSource {
  ArchivedProductDataSource({
    required this.products,
    required this.context,
  });

  final BuildContext context;
  final List<Product> products;

  void viewProduct(Product product) {
    showDialog(
      context: context,
      builder: (dialogContext) => ProductInformationContentDialog(
        product: product,
        dialogContext: dialogContext,
        accessLevel: AccessLevel.staff,
      ),
    );
  }

  @override
  DataRow getRow(int index) {
    final product = products[index];

    return DataRow(
      cells: [
        DataCell(Text(product.id.toString(), style: TextStyles.body)),
        DataCell(Text(product.sku, style: TextStyles.body)),
        DataCell(Text(product.name, style: TextStyles.body)),
        DataCell(Text(product.categoryName ?? '', style: TextStyles.body)),
        DataCell(Text(CurrencyFormatter.full(product.salePrice), style: TextStyles.body)),
        DataCell(
          DropDownButton(
            title: const Text('Actions', style: TextStyles.body),
            items: [
              MenuFlyoutItem(
                text: const Text('Make Active', style: TextStyles.body),
                onPressed: () =>
                    context.read<ProductListBloc>().add(UnarchiveProductEvent(product)),
              ),
            ],
          ),
        )
      ],
      onSelectChanged: (_) => viewProduct(product),
    );
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => products.length;

  @override
  int get selectedRowCount => 0;
}
