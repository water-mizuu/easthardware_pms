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
    required this.criticalLevel,
    required this.deadStockThreshold,
    required this.fastMovingStockThreshold,
    required this.creationDate,
    required this.creatorId,
    this.archiveStatus,
    this.isBelowCriticalLevel,
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
      criticalLevel: (map['critical_level'] as num).toDouble(),
      deadStockThreshold: (map['dead_stock_threshold'] as num).toDouble(),
      fastMovingStockThreshold: (map['fast_moving_threshold'] as num).toDouble(),
      creationDate: map['creation_date']?.toString() ?? '',
      creatorId: map['creator_id'] as int,
      archiveStatus: map['archive_status'] as int,
      isBelowCriticalLevel: map['is_below_critical_level'] == 1,
      isFastMovingStock: map['is_fast_moving_stock'] == 1,
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
  final double criticalLevel;
  final double deadStockThreshold;
  final double fastMovingStockThreshold;
  final String creationDate;
  final int creatorId;
  final int? archiveStatus;
  final bool? isBelowCriticalLevel;
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
    double criticalLevel,
    double deadStockThreshold,
    double fastMovingStockThreshold,
    String creationDate,
    int creatorId,
    int archiveStatus,
    bool? isBelowCriticalLevel,
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
      Object? criticalLevel = undefined,
      Object? deadStockThreshold = undefined,
      Object? fastMovingStockThreshold = undefined,
      Object? creationDate = undefined,
      Object? creatorId = undefined,
      Object? archiveStatus = undefined,
      Object? isBelowCriticalLevel = undefined,
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
        criticalLevel: criticalLevel.or(this.criticalLevel),
        deadStockThreshold: deadStockThreshold.or(this.deadStockThreshold),
        fastMovingStockThreshold: fastMovingStockThreshold.or(this.fastMovingStockThreshold),
        creationDate: creationDate.or(this.creationDate),
        creatorId: creatorId.or(this.creatorId),
        archiveStatus: archiveStatus.or(this.archiveStatus),
        isBelowCriticalLevel: isBelowCriticalLevel.or(this.isBelowCriticalLevel),
        isFastMovingStock: isFastMovingStock.or(this.isFastMovingStock),
        isDeadStock: isDeadStock.or(this.isDeadStock),
      );
    };
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'name': name,
      'category': categoryId,
      'sku': sku,
      'sale_price': salePrice,
      'order_cost': orderCost,
      'quantity': quantity,
      'main_unit': mainUnit,
      'description': description,
      'critical_level': criticalLevel,
      'dead_stock_threshold': deadStockThreshold,
      'fast_moving_threshold': fastMovingStockThreshold,
      'creation_date': creationDate,
      'creator_id': creatorId,
      'archive_status': archiveStatus ?? 0,
    };
  }
}
