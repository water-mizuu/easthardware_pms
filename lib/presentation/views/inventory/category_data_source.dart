import 'dart:async';

import 'package:easthardware_pms/domain/models/category.dart';
import 'package:easthardware_pms/presentation/views/inventory/manage_categories_page.dart';
import 'package:easthardware_pms/presentation/widgets/helper/data_row_mapper.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' show DataRow, DataTableSource;

class CategoryDataSource extends DataTableSource {
  CategoryDataSource({
    required this.context,
    required this.categories,
    required this.categoryProductCounts,
  });

  final List<Category> categories;
  final BuildContext context;
  final Map<int, int> categoryProductCounts;

  @override
  DataRow? getRow(int index) {
    final category = categories[index];
    final productCount = categoryProductCounts[category.id] ?? 0;

    return DataRowMapper.mapCategoryToRow(
      category,
      productCount,
      () {
        unawaited(showContentDialog(context, category));
      },
    );
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => categories.length;

  @override
  int get selectedRowCount => 0;
}
