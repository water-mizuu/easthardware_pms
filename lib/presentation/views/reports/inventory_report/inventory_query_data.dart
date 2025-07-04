import 'package:easthardware_pms/domain/models/category.dart';
import 'package:easthardware_pms/domain/models/invoice.dart';
import 'package:easthardware_pms/domain/models/invoice_product.dart';
import 'package:easthardware_pms/domain/models/order.dart';
import 'package:easthardware_pms/domain/models/order_product.dart';
import 'package:easthardware_pms/domain/models/product.dart';
import 'package:easthardware_pms/presentation/bloc/inventory/inventory_display/'
    'inventory_display_enum.dart';
import 'package:easthardware_pms/presentation/views/dashboard/cards/sales_overview.dart';
import 'package:easthardware_pms/utils/duration.dart';
import 'package:easthardware_pms/utils/levenshtein.dart';
import 'package:easthardware_pms/utils/undefined.dart';
import 'package:equatable/equatable.dart';

class InventoryQueryData with EquatableMixin {
  const InventoryQueryData({
    required this.date,
    required this.searchQuery,
    required this.category,
    required this.sortBy,
    required this.filter,
    this.rowLimit,
  });

  InventoryQueryData.empty()
      : date = DateTime.now().zeroedTime(),
        searchQuery = '',
        category = null,
        sortBy = InventoryDisplaySortBy.nameAscending,
        filter = null,
        rowLimit = null;

  final DateTime? date;
  final String searchQuery;
  final Category? category;
  final InventoryDisplaySortBy sortBy;
  final InventoryDisplayFilter? filter;
  final int? rowLimit;

  @override
  List<Object?> get props => [date, searchQuery, category, sortBy, filter, rowLimit];

  InventoryQueryData Function({
    DateTime? date,
    String searchQuery,
    Category? category,
    InventoryDisplaySortBy sortBy,
    InventoryDisplayFilter? filter,
    int? rowLimit,
  }) get copyWith {
    return ({
      Object? date = undefined,
      Object? searchQuery = undefined,
      Object? category = undefined,
      Object? sortBy = undefined,
      Object? filter = undefined,
      Object? rowLimit = undefined,
    }) {
      return InventoryQueryData(
        date: date.or(this.date),
        searchQuery: searchQuery.or(this.searchQuery),
        category: category.or(this.category),
        sortBy: sortBy.or(this.sortBy),
        filter: filter.or(this.filter),
        rowLimit: rowLimit.or(this.rowLimit),
      );
    };
  }

  List<Product> call(
    List<Product> products, {
    required List<Invoice> allInvoices,
    required List<InvoiceProduct> allInvoiceProducts,
    required List<Order> allOrders,
    required List<OrderProduct> allOrderProducts,
  }) {
    var result = products;

    if (date case final queryDate?) {
      /// We only take the products that were created before or on the query date.
      result = result
          .where((p) => DateTime.parse(p.creationDate).isBefore(queryDate.add(1.days)))
          .toList();

      /// We add back the quantities of the products that were invoiced after the query date.
      for (final invoice in allInvoices) {
        if (!invoice.creationDate.isAfter(queryDate)) continue;

        for (final product in allInvoiceProducts) {
          if (product.invoiceId != invoice.id) continue;

          final found = result.indexed //
              .where((p) => p.$2.id == product.productId)
              .firstOrNull;

          if (found case (final index, final item)) {
            result[index] = item.copyWith(quantity: item.quantity + product.quantity);
          }
        }
      }

      /// We remove the quantities of the products that were ordered after the query date.
      for (final order in allOrders) {
        if (!order.creationDate.isAfter(queryDate)) continue;

        for (final product in allOrderProducts) {
          if (product.orderId != order.id) continue;

          final found = result.indexed //
              .where((p) => p.$2.id == product.productId)
              .firstOrNull;

          if (found case (final index, final item)) {
            result[index] = item.copyWith(quantity: item.quantity - product.quantity);
          }
        }
      }

      if (!queryDate.zeroedTime().isAtSameMomentAs(DateTime.now().zeroedTime())) {
        for (var i = 0; i < result.length; ++i) {
          /// We remove the statuses as they are not computable for this report.
          result[i] = result[i].copyWith(
            isBelowReorderPoint: false,
            isDeadStock: false,
            isFastMovingStock: false,
          );
        }
      }
    }

    if (filter case final filter?) {
      result = result.where((p) => filter.call(p)).toList();
    }

    if (category case final category?) {
      result = result.where((p) => p.categoryId == category.id).toList();
    }

    result = Levenshtein.rankItems<Product>(
      result,
      searchQuery,
      (product) => {
        product.sku,
        product.name,
        if (product.description case final description?) description,
        if (product.categoryName case final categoryName?) categoryName,
      },
      sortBy.compareProducts,
    );

    if (rowLimit case final limit?) {
      result = result.take(limit).toList();
    }

    return result;
  }
}
