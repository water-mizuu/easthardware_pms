import 'package:easthardware_pms/data/database/dao/dao_base.dart';
import 'package:easthardware_pms/data/database/tables/order_items_table.dart';
import 'package:easthardware_pms/data/database/database_helper.dart';
import 'package:easthardware_pms/domain/models/order_item.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

abstract interface class OrderItemsDao {
  factory OrderItemsDao(DatabaseHelper? databaseHelper) = OrderItemsDaoImpl._;
  Future<List<OrderItem>> getAllOrderItems();
  Future<OrderItem?> getOrderItemById(int id);
  Future<OrderItem> insertOrderItem(OrderItem OrderItem);
  Future<OrderItem> updateOrderItem(OrderItem OrderItem);
  Future<void> deleteOrderItem(int id);
  Future<List<OrderItem>> getOrderItemsByOrderId(int orderId);
  Future<void> deleteOrderItemByOrderId(int orderId);
}

final class OrderItemsDaoImpl extends DaoBase implements OrderItemsDao {
  OrderItemsDaoImpl._(super.databaseHelper);

  /// Returns a list of all order products in the database.
  ///
  @override
  Future<List<OrderItem>> getAllOrderItems() async {
    final db = databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(OrderItemsTable.TABLE_NAME);
    return List.generate(maps.length, (i) {
      return OrderItem.fromMap(maps[i]);
    });
  }

  /// Returns an order product by its ID.
  /// If no order product is found, returns null.
  ///
  @override
  Future<OrderItem?> getOrderItemById(int id) async {
    final db = databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      OrderItemsTable.TABLE_NAME,
      where: '${OrderItemsTable.ORDER_ITEMS_ID} = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return OrderItem.fromMap(maps.first);
    }
    return null;
  }

  /// Inserts a new order product into the database.
  @override
  Future<OrderItem> insertOrderItem(OrderItem OrderItem) async {
    final db = databaseHelper.database;
    final id = await db.insert(
      OrderItemsTable.TABLE_NAME,
      OrderItem.toMap(),
      conflictAlgorithm: ConflictAlgorithm.fail,
    );
    return OrderItem.copyWith(id: id);
  }

  /// Updates an existing order product in the database.
  ///
  @override
  Future<OrderItem> updateOrderItem(OrderItem OrderItem) async {
    final db = databaseHelper.database;
    await db.update(
      OrderItemsTable.TABLE_NAME,
      OrderItem.toMap(),
      where: '${OrderItemsTable.ORDER_ITEMS_ID} = ?',
      whereArgs: [OrderItem.id],
    );
    return OrderItem;
  }

  /// Deletes an order product from the database by its ID.
  @override
  Future<void> deleteOrderItem(int id) async {
    final db = databaseHelper.database;
    await db.delete(
      OrderItemsTable.TABLE_NAME,
      where: '${OrderItemsTable.ORDER_ITEMS_ID} = ?',
      whereArgs: [id],
    );
  }

  /// Returns a list of order products by their order ID.
  @override
  Future<List<OrderItem>> getOrderItemsByOrderId(int orderId) async {
    final db = databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      OrderItemsTable.TABLE_NAME,
      where: '${OrderItemsTable.ORDER_ITEMS_ORDER_ID} = ?',
      whereArgs: [orderId],
    );
    return List.generate(maps.length, (i) {
      return OrderItem.fromMap(maps[i]);
    });
  }
  
   @override
  Future<void> deleteOrderItemByOrderId(int orderId) async{
    final db = databaseHelper.database;
    await db.delete(
      OrderItemsTable.TABLE_NAME,
      where: '${OrderItemsTable.ORDER_ITEMS_ORDER_ID} = ?',
      whereArgs: [orderId],
    );
  }
}
