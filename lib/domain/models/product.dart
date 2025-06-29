// filepath: /Users/michael/Programming/projects/dart/flutter/easthardware_pms/lib/domain/models/product.dart
import 'package:easthardware_pms/utils/undefined.dart';

class Product {
  Product({
    this.id,
    required this.sku,
    required this.name,
    required this.categoryId,
    this.categoryName,
    required this.description,
    required this.salePrice,
    required this.orderCost,
    required this.quantity,
    required this.mainUnit,
    this.reorderPoint,
    required this.minReorderDelay,
    required this.maxReorderDelay,
    required this.deadStockThreshold,
    required this.fastMovingStockThreshold,
    required this.creationDate,
    required this.creatorId,
    this.archiveStatus,
    this.isBelowReorderPoint,
    this.isFastMovingStock,
    this.isDeadStock,
  });

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] as int?,
      name: map['name']?.toString() ?? '',
      sku: map['sku']?.toString() ?? '',
      categoryId: map['category'] as int?,
      description: map['description']?.toString(),
      salePrice: (map['sale_price'] as num).toDouble(),
      orderCost: (map['order_cost'] as num).toDouble(),
      quantity: (map['quantity'] as num).toDouble(),
      mainUnit: map['main_unit']?.toString() ?? '',
      minReorderDelay: map['min_reorder_delay'] as int,
      maxReorderDelay: map['max_reorder_delay'] as int,
      reorderPoint: map['reorder_point'] != null ? (map['reorder_point'] as num).toDouble() : null,
      deadStockThreshold: (map['dead_stock_threshold'] as num).toDouble(),
      fastMovingStockThreshold: (map['fast_moving_threshold'] as num).toDouble(),
      creationDate: map['creation_date']?.toString() ?? '',
      creatorId: map['creator_id'] as int,
      archiveStatus: map['archive_status'] as int,
      isBelowReorderPoint: map['is_below_reorder_point'] == 1,
      isFastMovingStock: map['is_fast_moving'] == 1,
      isDeadStock: map['is_dead_stock'] == 1,
    );
  }
  final int? id;
  final String name;
  final int? categoryId;
  String? categoryName;
  final String sku;
  final String? description;
  final double salePrice;
  final double orderCost;
  final double quantity;
  final String mainUnit;
  final int minReorderDelay;
  final int maxReorderDelay;
  final double? reorderPoint;
  final double deadStockThreshold;
  final double fastMovingStockThreshold;
  final String creationDate;
  final int creatorId;
  final int? archiveStatus;
  final bool? isBelowReorderPoint;
  final bool? isFastMovingStock;
  final bool? isDeadStock;

  Product Function({
    int? id,
    String name,
    String sku,
    int? categoryId,
    String? categoryName,
    String? description,
    double salePrice,
    double orderCost,
    double quantity,
    String mainUnit,
    int minReorderDelay,
    int maxReorderDelay,
    double? reorderPoint,
    double deadStockThreshold,
    double fastMovingStockThreshold,
    String creationDate,
    int creatorId,
    int archiveStatus,
    bool? isBelowReorderPoint,
    bool? isFastMovingStock,
    bool? isDeadStock,
  }) get copyWith {
    return ({
      Object? id = undefined,
      Object? name = undefined,
      Object? sku = undefined,
      Object? categoryId = undefined,
      Object? categoryName = undefined,
      Object? description = undefined,
      Object? salePrice = undefined,
      Object? orderCost = undefined,
      Object? quantity = undefined,
      Object? mainUnit = undefined,
      Object? minReorderDelay = undefined,
      Object? maxReorderDelay = undefined,
      Object? criticalLevel = undefined,
      Object? reorderPoint = undefined,
      Object? deadStockThreshold = undefined,
      Object? fastMovingStockThreshold = undefined,
      Object? creationDate = undefined,
      Object? creatorId = undefined,
      Object? archiveStatus = undefined,
      Object? isBelowReorderPoint = undefined,
      Object? isFastMovingStock = undefined,
      Object? isDeadStock = undefined,
    }) {
      return Product(
        id: id.or(this.id),
        name: name.or(this.name),
        sku: sku.or(this.sku),
        categoryId: categoryId.or(this.categoryId),
        categoryName: categoryName.or(this.categoryName),
        description: description.or(this.description),
        salePrice: salePrice.or(this.salePrice),
        orderCost: orderCost.or(this.orderCost),
        quantity: quantity.or(this.quantity),
        mainUnit: mainUnit.or(this.mainUnit),
        minReorderDelay: minReorderDelay.or(this.minReorderDelay),
        maxReorderDelay: maxReorderDelay.or(this.maxReorderDelay),
        reorderPoint: reorderPoint.or(this.reorderPoint),
        deadStockThreshold: deadStockThreshold.or(this.deadStockThreshold),
        fastMovingStockThreshold: fastMovingStockThreshold.or(this.fastMovingStockThreshold),
        creationDate: creationDate.or(this.creationDate),
        creatorId: creatorId.or(this.creatorId),
        archiveStatus: archiveStatus.or(this.archiveStatus),
        isBelowReorderPoint: isBelowReorderPoint.or(this.isBelowReorderPoint),
        isFastMovingStock: isFastMovingStock.or(this.isFastMovingStock),
        isDeadStock: isDeadStock.or(this.isDeadStock),
      );
    };
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'name': name,
      'category': categoryId,
      'sku': sku,
      'sale_price': salePrice,
      'order_cost': orderCost,
      'quantity': quantity,
      'main_unit': mainUnit,
      'description': description,
      'min_reorder_delay': minReorderDelay,
      'max_reorder_delay': maxReorderDelay,
      'dead_stock_threshold': deadStockThreshold,
      'fast_moving_threshold': fastMovingStockThreshold,
      'creation_date': creationDate,
      'creator_id': creatorId,
      'archive_status': archiveStatus ?? 0,
    };

    // Only add id to the map if it's not null
    if (id != null) {
      map['id'] = id;
    }

    return map;
  }
}
