import 'package:easthardware_pms/data/database/dao/dao_base.dart';
import 'package:easthardware_pms/data/database/database_helper.dart';
import 'package:easthardware_pms/domain/models/payment.dart';

abstract interface class PaymentDao {
  factory PaymentDao(DatabaseHelper? databaseHelper) {
    return PaymentDaoImpl._(databaseHelper);
  }

  Future<List<Payment>> getAllPayments();
  Future<Payment?> getPaymentById(int id);
  Future<Payment> insertPayment(Payment payment);
  Future<Payment> updatePayment(Payment payment);
  Future<void> deletePayment(int id);
}

final class PaymentDaoImpl extends DaoBase implements PaymentDao {
  PaymentDaoImpl._(super.databaseHelper);

  @override
  Future<List<Payment>> getAllPayments() async {
    final db = databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('payments');
    return List.generate(maps.length, (i) {
      return Payment.fromMap(maps[i]);
    });
  }

  @override
  Future<Payment?> getPaymentById(int id) async {
    final db = databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'payments',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Payment.fromMap(maps.first);
    }
    return null;
  }

  @override
  Future<Payment> insertPayment(Payment payment) async {
    final db = databaseHelper.database;
    final id = await db.insert('payments', payment.toMap());
    return payment.copyWith(id: id);
  }

  @override
  Future<Payment> updatePayment(Payment payment) async {
    final db = databaseHelper.database;
    await db.update(
      'payments',
      payment.toMap(),
      where: 'id = ?',
      whereArgs: [payment.id],
    );
    return payment;
  }

  @override
  Future<void> deletePayment(int id) async {
    final db = databaseHelper.database;
    await db.delete(
      'payments',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
