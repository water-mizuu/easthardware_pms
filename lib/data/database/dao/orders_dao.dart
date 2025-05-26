import 'package:easthardware_pms/data/database/dao/dao_base.dart';
import 'package:easthardware_pms/data/database/database_helper.dart';
import 'package:easthardware_pms/domain/models/order.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

abstract interface class OrdersDao {
  factory OrdersDao(DatabaseHelper? databaseHelper) {
    return OrdersDaoImpl._(databaseHelper);
  }
  Future<List<Order>> getAllOrders();
  Future<Order?> getOrderById(int id);
  Future<Order?> getOrderByUid(String uid);
  Future<Order> insertOrder(Order order);
  Future<Order> updateOrder(Order order);
  Future<void> deleteOrder(int id);

  Future<List<Order>> getOrdersByPayeeName(String payeeName);
  Future<List<Order>> getOrdersByExpenseType(int expenseType);
  Future<List<Order>> getOrdersByDateRange(DateTime startDate, DateTime endDate);
  Future<List<Order>> getOrdersByPaymentMethod(int paymentMethod);
  Future<List<Order>> getOrdersByAmountDue(double minAmount, double maxAmount);
  Future<List<Order>> getOrdersByCreatorId(int creatorId);
  Future<List<Order>> getOrdersByProductNames(List<String> productNames);
  Future<int> getTotalAmountDue();
  Future<int> getTotalOrderCount();
}

final class OrdersDaoImpl extends DaoBase implements OrdersDao {
  OrdersDaoImpl._(super.databaseHelper);

  @override
  Future<void> deleteOrder(int id) async {
    final db = databaseHelper.database;
    await db.delete(
      'orders',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<List<Order>> getAllOrders() async {
    final db = databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('orders');
    return List.generate(maps.length, (i) {
      return Order.fromMap(maps[i]);
    });
  }

  @override
  Future<Order?> getOrderById(int id) async {
    final db = databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'orders',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Order.fromMap(maps.first);
    }
    return null;
  }

  @override
  Future<List<Order>> getOrdersByAmountDue(double minAmount, double maxAmount) async {
    final db = databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'orders',
      where: 'amount_due BETWEEN ? AND ?',
      whereArgs: [minAmount, maxAmount],
    );
    return List.generate(maps.length, (i) {
      return Order.fromMap(maps[i]);
    });
  }

  @override
  Future<List<Order>> getOrdersByCreatorId(int creatorId) async {
    final db = databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'orders',
      where: 'creator_id = ?',
      whereArgs: [creatorId],
    );
    return List.generate(maps.length, (i) {
      return Order.fromMap(maps[i]);
    });
  }

  @override
  Future<List<Order>> getOrdersByDateRange(DateTime startDate, DateTime endDate) async {
    final db = databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'orders',
      where: 'order_date BETWEEN ? AND ?',
      whereArgs: [startDate.toIso8601String(), endDate.toIso8601String()],
    );
    return List.generate(maps.length, (i) {
      return Order.fromMap(maps[i]);
    });
  }

  @override
  Future<List<Order>> getOrdersByExpenseType(int expenseType) async {
    final db = databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'orders',
      where: 'expense_type = ?',
      whereArgs: [expenseType],
    );
    return List.generate(maps.length, (i) {
      return Order.fromMap(maps[i]);
    });
  }

  @override
  Future<List<Order>> getOrdersByPayeeName(String payeeName) async {
    final db = databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'orders',
      where: 'payee_name = ?',
      whereArgs: [payeeName],
    );
    return List.generate(maps.length, (i) {
      return Order.fromMap(maps[i]);
    });
  }

  @override
  Future<List<Order>> getOrdersByPaymentMethod(int paymentMethod) async {
    final db = databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'orders',
      where: 'payment_method = ?',
      whereArgs: [paymentMethod],
    );
    return List.generate(maps.length, (i) {
      return Order.fromMap(maps[i]);
    });
  }

  @override
  Future<List<Order>> getOrdersByProductNames(List<String> productNames) async {
    final db = databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      'SELECT DISTINCT orders.* FROM orders '
      'JOIN order_products ON orders.id = order_products.order_id '
      'WHERE order_products.product_id IN (${productNames.join(',')})',
    );
    return List.generate(maps.length, (i) {
      return Order.fromMap(maps[i]);
    });
  }

  @override
  Future<Order> insertOrder(Order order) async {
    final db = databaseHelper.database;
    final id = await db.insert(
      'insert',
      order.toMap(),
      conflictAlgorithm: ConflictAlgorithm.fail,
    );
    return order.copyWith(id: id);
  }

  @override
  Future<Order> updateOrder(Order order) async {
    final db = databaseHelper.database;
    await db.update(
      'orders',
      order.toMap(),
      where: 'id = ?',
      whereArgs: [order.id],
    );
    return order;
  }

  @override
  Future<Order?> getOrderByUid(String uid) async {
    final db = databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'orders',
      where: 'uid = ?',
      whereArgs: [uid],
    );
    if (maps.isNotEmpty) {
      return Order.fromMap(maps.first);
    }
    return null;
  }

  @override
  Future<int> getTotalAmountDue() async {
    final db = databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      'SELECT SUM(amount_due) as total FROM orders',
    );
    if (maps.isNotEmpty) {
      return maps.first['total'] ?? 0;
    }
    return 0;
  }

  @override
  Future<int> getTotalOrderCount() async {
    final db = databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      'SELECT COUNT(*) as total FROM orders',
    );
    if (maps.isNotEmpty) {
      return maps.first['total'] ?? 0;
    }
    return 0;
  }
}
