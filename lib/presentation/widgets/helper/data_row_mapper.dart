import 'package:easthardware_pms/domain/enums/enums.dart';
import 'package:easthardware_pms/domain/models/category.dart';
import 'package:easthardware_pms/domain/models/invoice.dart';
import 'package:easthardware_pms/domain/models/order.dart';
import 'package:easthardware_pms/domain/models/product.dart';
import 'package:easthardware_pms/domain/models/unit.dart';
import 'package:easthardware_pms/domain/models/user.dart';
import 'package:easthardware_pms/domain/models/user_log.dart';
import 'package:easthardware_pms/presentation/bloc/order/expense_type_list/expense_type_list_bloc.dart';
import 'package:easthardware_pms/presentation/models/data_cell_functions.dart';
import 'package:easthardware_pms/presentation/models/form_product.dart';
import 'package:easthardware_pms/presentation/widgets/helper/currency_formatter.dart';
import 'package:easthardware_pms/presentation/widgets/text.dart';
import 'package:easthardware_pms/presentation/widgets/ui/badges.dart';
import 'package:easthardware_pms/presentation/widgets/ui/compound_button.dart';
import 'package:easthardware_pms/presentation/widgets/ui/styles.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' show DataCell, DataRow;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class DataRowMapper {
  static DataRow mapProductToRow(
    Product product, {
    required void Function()? viewAction,
    required void Function()? editAction,
    required void Function()? orderAction,
  }) {
    final actionsCell = DataCell(
      DropDownButton(
        title: const Text('Actions', style: TextStyles.body),
        items: [
          if (editAction != null)
            MenuFlyoutItem(
              text: const Text('Edit Product', style: TextStyles.body),
              onPressed: editAction,
            ),
          if (orderAction != null)
            MenuFlyoutItem(
              text: const Text('Place Order', style: TextStyles.body),
              onPressed: orderAction,
            )
        ],
      ),
    );

    if (product.isBelowCriticalLevel == true) {
      return DataRow(
        onSelectChanged: viewAction != null ? (_) => viewAction() : null,
        cells: [
          DataCell(
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                product.name,
                style: TextStyles.body,
              ),
            ),
          ),
          DataCell(Align(
            alignment: Alignment.centerLeft,
            child: Text(
              product.categoryName ?? '',
              style: TextStyles.body,
            ),
          )),
          DataCell(
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                CurrencyFormatter.full(product.salePrice),
                style: TextStyles.body,
              ),
            ),
          ),
          DataCell(
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${product.quantity.toString()} ${product.mainUnit}(s)',
                style: TextStyles.body,
              ),
            ),
          ),
          DataCell(
            Row(
              children: [Badges.bad('Low Stock')],
            ),
          ),
          actionsCell,
        ],
      );
    }

    if (product.isFastMovingStock == true) {
      return DataRow(cells: [
        DataCell(
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              product.name,
              style: TextStyles.body,
            ),
          ),
        ),
        DataCell(
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              product.categoryName ?? '',
              style: TextStyles.body,
            ),
          ),
        ),
        DataCell(
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              CurrencyFormatter.full(product.salePrice),
              style: TextStyles.body,
            ),
          ),
        ),
        DataCell(
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '${product.quantity.toString()} ${product.mainUnit}(s)',
              style: TextStyles.body,
            ),
          ),
        ),
        DataCell(
          Row(
            children: [Badges.good('Fast Moving')],
          ),
        ),
        actionsCell,
      ]);
    }

    if (product.isDeadStock == true) {
      return DataRow(
        onSelectChanged: viewAction != null ? (_) => viewAction() : null,
        cells: [
          DataCell(
            Align(
              alignment: Alignment.centerLeft,
              child: Text(product.name),
            ),
          ),
          DataCell(
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                product.categoryName ?? 'Uncategorized',
                style: TextStyles.body,
              ),
            ),
          ),
          DataCell(
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                CurrencyFormatter.full(product.salePrice),
                style: TextStyles.body,
              ),
            ),
          ),
          DataCell(
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${product.quantity.toString()} ${product.mainUnit}(s)',
                style: TextStyles.body,
              ),
            ),
          ),
          DataCell(
            Row(
              children: [Badges.dull('Dead Stock')],
            ),
          ),
          actionsCell,
        ],
      );
    }

    return DataRow(
      onSelectChanged: viewAction != null ? (_) => viewAction() : null,
      cells: [
        DataCell(
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              product.name,
              style: TextStyles.body,
            ),
          ),
        ),
        DataCell(
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              product.categoryName ?? 'Uncategorized',
              style: TextStyles.body,
            ),
          ),
        ),
        DataCell(
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              CurrencyFormatter.full(product.salePrice),
              style: TextStyles.body,
            ),
          ),
        ),
        DataCell(
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '${product.quantity.toString()} ${product.mainUnit}(s)',
              style: TextStyles.body,
            ),
          ),
        ),
        DataCell(
          Row(
            children: [Badges.normal('Normal')],
          ),
        ),
        actionsCell,
      ],
    );
  }

  static DataRow mapCategoryToRow(Category category, int productCount, Function()? action) {
    return DataRow(cells: [
      DataCell(Text(category.name, style: TextStyles.body)),
      DataCell(Text(productCount.toString(), style: TextStyles.body)),
      DataCell(DropDownButton(
        title: const Text('Actions', style: TextStyles.body),
        items: [
          MenuFlyoutItem(
            text: const Text('View Products', style: TextStyles.body),
            onPressed: action,
          ),
          MenuFlyoutItem(
            text: const Text('Edit Category', style: TextStyles.body),
            onPressed: action,
          ),
        ],
      )),
    ]);
  }

  static DataRow mapExpenseTypeToRow(dynamic expenseType, int orderCount, Function()? action) {
    return DataRow(cells: [
      DataCell(Text(expenseType.id!.toString(), style: TextStyles.body)),
      DataCell(Text(expenseType.name.toString(), style: TextStyles.body)),
      DataCell(Text(orderCount.toString(), style: TextStyles.body)),
      DataCell(action == null
          ? const Text('', style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey))
          : HyperlinkButton(onPressed: action, child: const Text('Edit'))),
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
    final invoiceCustomer = invoice.customerName.isNotEmpty //
        ? invoice.customerName
        : "Unnamed Customer";
    final invoiceTotal = CurrencyFormatter.full(invoice.amountDue);

    return DataRow(cells: [
      DataCell(Text(invoiceDate)),
      DataCell(Text(invoiceId)),
      DataCell(Text(invoiceCustomer)),
      DataCell(Text(invoiceTotal)),
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
          }).toList(),
        ),
      )),
      DataCell(
        TextFormBox(
          onChanged: (value) => functions.onDescriptionChanged,
          controller: TextEditingController(text: product.description),
        ),
      ),
      // Quantity
      DataCell(
        CompoundButton(
          onTextChanged: (value) => functions.onQuantityChanged,
          onComboBoxSelected: (value) => functions.onUnitSelected,
          items: units
              .map((unit) => ComboBoxItem(
                    value: unit,
                    child: Text(unit.name),
                  ))
              .toList(),
          text: product.quantity.toString(),
        ),
      ),
      // Rate
      DataCell(
        TextFormBox(
          controller: TextEditingController(text: product.rate.toString()),
        ),
      ),
      // Discount
      DataCell(
        ComboBox(
          items: DiscountType.values.map((type) => ComboBoxItem(child: Text(type.name))).toList(),
        ),
      ),
      // Amount
      DataCell(TextFormBox()),
      // Delete
      DataCell(
        IconButton(
          icon: const Icon(FluentIcons.remove),
          onPressed: () {},
        ),
      )
    ]);
  }

  static DataRow mapOrderToRow(Order order, void Function() onEditPressed) {
    final orderId = order.id?.toString() ?? 'N/A';
    final orderDate = DateFormat.yMMMMd().format(order.orderDate);
    final payee = order.payeeName.isNotEmpty == true ? order.payeeName : 'Unknown Payee';
    // Map expenseType to label
    // final expenseType = order.expenseType.toString();
    final amount = CurrencyFormatter.full(order.amountDue);

    return DataRow(cells: [
      DataCell(Text(orderId)),
      DataCell(Text(orderDate)),
      DataCell(Text(payee)),
      DataCell(Builder(builder: (context) {
        final expenseType = order.expenseType;
        final expenseTypeLabel = context
                .read<ExpenseTypeListBloc>()
                .state
                .expenseTypes
                .where((e) => e.id == expenseType)
                .firstOrNull
                ?.name ??
            'Unknown';

        return Text(expenseTypeLabel);
      })),
      DataCell(Text(amount)),
      DataCell(HyperlinkButton(onPressed: onEditPressed, child: const Text('Edit'))),
    ]);
  }

  static DataRow mapOrderProductToRow(
    int index,
    FormProduct product,
    List<Product> products,
    List<Unit> units,
    OrderProductFunctions functions,
  ) {
    return DataRow(cells: [
      // No.
      DataCell(Text((index + 1).toString())),

      // Product with AutoSuggestBox
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
          }).toList(),
        ),
      )),

      // Description (TextFormBox)
      DataCell(TextFormBox(
        initialValue: product.description,
        onChanged: (value) => functions.onDescriptionChanged(value),
      )),

      // Quantity with CompoundButton (Text + ComboBox)
      DataCell(CompoundButton(
        text: product.quantity.toString(),
        onTextChanged: (value) => functions.onQuantityChanged(double.tryParse(value) ?? 0),
        onComboBoxSelected: (unit) => functions.onUnitSelected(unit),
        items: units
            .map((unit) => ComboBoxItem(
                  value: unit,
                  child: Text(unit.name),
                ))
            .toList(),
      )),

      // Rate (TextFormBox)
      DataCell(TextFormBox(
        controller: TextEditingController(text: product.rate.toString()),
        onChanged: (value) => functions.onRateChanged(double.tryParse(value) ?? 0),
      )),

      // Amount (TextFormBox, disabled)
      DataCell(TextFormBox(
        controller: TextEditingController(text: product.amount.toString()),
        enabled: false,
      )),

      // Actions - Delete button
      DataCell(
        IconButton(
          icon: const Icon(FluentIcons.remove),
          onPressed: () {},
        ),
      ),
    ]);
  }
}
