import 'package:easthardware_pms/domain/models/category.dart';
import 'package:easthardware_pms/domain/models/product.dart';
import 'package:easthardware_pms/domain/models/user.dart';
import 'package:easthardware_pms/domain/models/user_log.dart';
import 'package:easthardware_pms/presentation/widgets/data_row.dart';
import 'package:easthardware_pms/presentation/widgets/spacing.dart';
import 'package:easthardware_pms/presentation/widgets/text.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' show DataCell, DataRow;
import 'package:intl/intl.dart';

class DataRowMapper {
  static DataRow mapProductToRow(
    Product product, {
    required void Function() editAction,
  }) {
    const maxWidths = [
      480.0, // Name
      120.0, // Category
      null, // Price
      null, // Cost
      null, // Quantity
      null, // Actions
    ];

    if (product.isBelowCriticalLevel == true) {
      return WarningDataRow([
        DataCell(
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidths[0] ?? double.infinity),
            child: Text(product.name),
          ),
        ),
        DataCell(
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidths[1] ?? double.infinity),
            child: Text(product.categoryName!),
          ),
        ),
        DataCell(
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidths[2] ?? double.infinity),
            child: Text(product.salePrice.toString()),
          ),
        ),
        DataCell(
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidths[3] ?? double.infinity),
            child: Text(
              product.orderCost.toString(),
            ),
          ),
        ),
        DataCell(Row(
          children: [
            Text('${product.quantity.toString()} ${product.mainUnit}'),
            Spacing.h12,
            Icon(FluentIcons.alert_solid, color: Colors.red.lightest)
          ],
        )),
        DataCell(HyperlinkButton(onPressed: editAction, child: const Text('Edit')))
      ]);
    }
    if (product.isFastMovingStock == true) {
      return SuccessDataRow([
        DataCell(
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidths[0] ?? double.infinity),
            child: Text(product.name),
          ),
        ),
        DataCell(
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidths[1] ?? double.infinity),
            child: Text(product.categoryName!),
          ),
        ),
        DataCell(
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidths[2] ?? double.infinity),
            child: Text(product.salePrice.toString()),
          ),
        ),
        DataCell(
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidths[3] ?? double.infinity),
            child: Text(product.orderCost.toString()),
          ),
        ),
        DataCell(
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidths[4] ?? double.infinity),
            child: Text('${product.quantity.toString()} ${product.mainUnit}'),
          ),
        ),
        DataCell(
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidths[5] ?? double.infinity),
            child: HyperlinkButton(onPressed: editAction, child: const Text('Edit')),
          ),
        )
      ]);
    }
    if (product.isDeadStock == true) {
      return InfoDataRow([
        DataCell(
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidths[0] ?? double.infinity),
            child: Text(product.name),
          ),
        ),
        DataCell(
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidths[1] ?? double.infinity),
            child: Text(product.categoryName!),
          ),
        ),
        DataCell(
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidths[2] ?? double.infinity),
            child: Text(product.salePrice.toString()),
          ),
        ),
        DataCell(
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidths[3] ?? double.infinity),
            child: Text(product.orderCost.toString()),
          ),
        ),
        DataCell(
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidths[4] ?? double.infinity),
            child: Text('${product.quantity.toString()} ${product.mainUnit}'),
          ),
        ),
        DataCell(
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidths[5] ?? double.infinity),
            child: HyperlinkButton(onPressed: editAction, child: const Text('Edit')),
          ),
        )
      ]);
    }

    return DataRow(cells: [
      DataCell(
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidths[0] ?? double.infinity),
          child: Text(product.name),
        ),
      ),
      DataCell(
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidths[1] ?? double.infinity),
          child: Text(product.categoryName!),
        ),
      ),
      DataCell(
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidths[2] ?? double.infinity),
          child: Text(product.salePrice.toString()),
        ),
      ),
      DataCell(
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidths[3] ?? double.infinity),
          child: Text(product.orderCost.toString()),
        ),
      ),
      DataCell(
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidths[4] ?? double.infinity),
          child: Text('${product.quantity.toString()} ${product.mainUnit}'),
        ),
      ),
      DataCell(
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidths[5] ?? double.infinity),
          child: HyperlinkButton(onPressed: editAction, child: const Text('Edit')),
        ),
      )
    ]);
  }

  static DataRow mapCategoryToRow(Category category, int productCount, Function() action) {
    return DataRow(cells: [
      DataCell(Text(category.id!.toString())),
      DataCell(Text(category.name.toString())),
      DataCell(Text(productCount.toString())),
      DataCell(HyperlinkButton(onPressed: action, child: const Text('Edit'))),
    ]);
  }

  static DataRow mapUserToRow(User user, Function() action) {
    return DataRow(cells: [
      DataCell(Text('${user.firstName} ${user.lastName}')),
      DataCell(Text(user.accessLevel.name.toTitleCase())),
      DataCell(Text(DateFormat.yMMMMd().format(DateTime.parse(user.creationDate)))),
    ]);
  }

  static DataRow mapUserLogToRow(UserLog log, User user) {
    return DataRow(cells: [
      DataCell(Text('${log.id}')),
      DataCell(Text('${user.firstName} ${user.lastName}')),
      DataCell(Text(DateFormat.yMMMMd().format(log.eventTime))),
      DataCell(Text(DateFormat('hh:mm a').format(log.eventTime))),
      DataCell(Text(log.event)),
    ]);
  }
}
