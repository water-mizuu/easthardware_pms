import 'package:easthardware_pms/data/database/dao/dao_base.dart';
import 'package:easthardware_pms/data/database/database_helper.dart';
import 'package:easthardware_pms/domain/models/payment_method.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

abstract interface class PaymentMethodsDao {
  factory PaymentMethodsDao(DatabaseHelper? databaseHelper) {
    return PaymentMethodsDaoImpl._(databaseHelper);
  }
  Future<List<PaymentMethod>> getAllPaymentMethods();
  Future<PaymentMethod?> getPaymentMethodById(int id);
  Future<PaymentMethod> insertPaymentMethod(PaymentMethod paymentMethod);
  Future<PaymentMethod> updatePaymentMethod(PaymentMethod paymentMethod);
  Future<void> deletePaymentMethod(int id);
}

final class PaymentMethodsDaoImpl extends DaoBase implements PaymentMethodsDao {
  PaymentMethodsDaoImpl._(super.databaseHelper);

  @override
  Future<void> deletePaymentMethod(int id) async {
    final db = databaseHelper.database;
    await db.delete(
      'payment_methods',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<List<PaymentMethod>> getAllPaymentMethods() async {
    final db = databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('payment_methods');
    return List.generate(maps.length, (i) {
      return PaymentMethod.fromMap(maps[i]);
    });
  }

  @override
  Future<PaymentMethod?> getPaymentMethodById(int id) async {
    final db = databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'payment_methods',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return PaymentMethod.fromMap(maps.first);
    }
    return null;
  }

  @override
  Future<PaymentMethod> insertPaymentMethod(PaymentMethod paymentMethod) async {
    final db = databaseHelper.database;
    final id = await db.insert(
      'payment_methods',
      paymentMethod.toMap(),
      conflictAlgorithm: ConflictAlgorithm.fail,
    );
    return paymentMethod.copyWith(id: id);
  }

  @override
  Future<PaymentMethod> updatePaymentMethod(PaymentMethod paymentMethod) async {
    final db = databaseHelper.database;
    await db.update(
      'payment_methods',
      paymentMethod.toMap(),
      where: 'id = ?',
      whereArgs: [paymentMethod.id],
    );
    return paymentMethod;
  }
}
