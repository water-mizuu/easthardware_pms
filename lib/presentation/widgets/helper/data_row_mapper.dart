import 'package:easthardware_pms/domain/enums/enums.dart';
import 'package:easthardware_pms/domain/models/category.dart';
import 'package:easthardware_pms/domain/models/invoice.dart';
import 'package:easthardware_pms/domain/models/order.dart';
import 'package:easthardware_pms/domain/models/product.dart';
import 'package:easthardware_pms/domain/models/unit.dart';
import 'package:easthardware_pms/domain/models/user.dart';
import 'package:easthardware_pms/domain/models/user_log.dart';
import 'package:easthardware_pms/presentation/models/data_cell_functions.dart';
import 'package:easthardware_pms/presentation/models/form_product.dart';
import 'package:easthardware_pms/presentation/widgets/layout/spacing.dart';
import 'package:easthardware_pms/presentation/widgets/text.dart';
import 'package:easthardware_pms/presentation/widgets/ui/badge.dart';
import 'package:easthardware_pms/presentation/widgets/ui/compound_button.dart';
import 'package:easthardware_pms/presentation/widgets/ui/data_row.dart';
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

  static DataRow mapUserToRow(
    User user,
    bool isLoggedIn,
  ) {
    return DataRow(
      cells: [
        DataCell(Text('${user.firstName} ${user.lastName}')),
        DataCell(Text(user.accessLevel.name.toTitleCase())),
        DataCell(Text(DateFormat.yMMMMd().format(DateTime.parse(user.creationDate)))),
        if (isLoggedIn)
          DataCell(
            Container(
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.green.lightest),
                borderRadius: BorderRadius.circular(4.0),
              ),
              child: Text(
                'Logged In',
                style: TextStyle(
                  color: Colors.green.lightest,
                ),
              ),
            ),
          )
        else
          const DataCell(SizedBox.shrink())
      ],
    );
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

  static DataRow mapInvoiceToRow(Invoice invoice, Function() action) {
    final invoiceDate = DateFormat.yMMMMd().format(invoice.invoiceDate).toString();
    final invoiceId = invoice.id!.toString();
    final invoiceCustomer =
        invoice.customerName.isNotEmpty ? invoice.customerName : "Unnamed Customer";
    final invoiceTotal = invoice.amountDue.toString();

    final amountPaid = invoice.amountPaid ?? 0;
    final isPaid = invoice.amountDue - amountPaid == 0;
    final Widget statusBadge = isPaid
        ? Badge(
            color: Colors.green.light,
            child: Text("Paid", style: TextStyle(color: Colors.green)),
          )
        : Badge(
            color: Colors.red.light,
            child: Text("Unpaid", style: TextStyle(color: Colors.red)),
          );
    return DataRow(cells: [
      DataCell(Text(invoiceDate)),
      DataCell(Text(invoiceId)),
      DataCell(Text(invoiceCustomer)),
      DataCell(Text(invoiceTotal)),
      DataCell(statusBadge),
      DataCell(HyperlinkButton(onPressed: action, child: const Text('View'))),
    ]);
  }

  static DataRow mapInvoiceProductToRow(
    int index,
    FormProduct product,
    List<Product> products,
    List<Unit> units,
    InvoiceProductFunctions functions,
  ) {
    return DataRow(cells: [
      // Number
      DataCell(Text((index + 1).toString())),
      DataCell(SizedBox(
        height: 32,
        width: 128,
        child: AutoSuggestBox.form(
            foregroundDecoration: const BoxDecoration(border: Border()),
            onSelected: (value) {
              if (value.value != null) {
                functions.onProductSelected(value.value!);
              }
            },
            items: products.map((product) {
              return AutoSuggestBoxItem(
                value: product,
                label: product.name,
              );
            }).toList()),
      )),
      DataCell(TextFormBox(
          onChanged: (value) => functions.onDescriptionChanged,
          controller: TextEditingController(text: product.description))),
      // Quantity
      DataCell(CompoundButton(
          onTextChanged: (value) => functions.onQuantityChanged,
          onComboBoxSelected: (value) => functions.onUnitSelected,
          items: units
              .map((unit) => ComboBoxItem(
                    value: unit,
                    child: Text(unit.name),
                  ))
              .toList(),
          text: product.quantity.toString())),
      // Rate
      DataCell(TextFormBox(
        controller: TextEditingController(text: product.rate.toString()),
      )),
      // Discount
      DataCell(ComboBox(
          items: DiscountType.values.map((type) => ComboBoxItem(child: Text(type.name))).toList())),
      // Amount
      DataCell(TextFormBox()),
      // Delete
      DataCell(IconButton(icon: const Icon(FluentIcons.remove), onPressed: () {}))
    ]);
  }

  static DataRow mapOrderToRow(Order order, void Function() onViewPressed) {
    final orderId = order.id?.toString() ?? 'N/A';
    final orderDate = DateFormat.yMMMMd().format(order.orderDate);
    final payee = order.payeeName.isNotEmpty == true ? order.payeeName : 'Unknown Payee';
    final expenseType = order.expenseType.toString();
    final amount = order.amountDue.toString();

    return DataRow(cells: [
      DataCell(Text(orderId)),
      DataCell(Text(orderDate)),
      DataCell(Text(payee)),
      DataCell(Text(expenseType)),
      DataCell(Text(amount)),
      DataCell(HyperlinkButton(onPressed: onViewPressed, child: const Text('View'))),
    ]);
  }
}
