import 'dart:async';

import 'package:easthardware_pms/domain/models/category.dart';
import 'package:easthardware_pms/presentation/cubit/inventory/category_display/category_display_cubit.dart';
import 'package:easthardware_pms/presentation/views/inventory/manage_categories_page.dart';
import 'package:easthardware_pms/presentation/widgets/helper/data_row_mapper.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' show DataRow, DataTableSource;

class CategoryDataSource extends DataTableSource {
  CategoryDataSource({
    required this.context,
    required this.categories,
  });

  final List<DisplayCategory> categories;
  final BuildContext context;

  @override
  DataRow? getRow(int index) {
    final category = categories[index];

    return DataRowMapper.mapCategoryToRow(
      category,
      () {
        unawaited(showContentDialog(context, category.category));
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
