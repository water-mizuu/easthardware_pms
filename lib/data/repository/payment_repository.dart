import 'package:easthardware_pms/data/database/dao/payment_dao.dart';
import 'package:easthardware_pms/data/database/database_helper.dart';
import 'package:easthardware_pms/domain/models/payment.dart';
import 'package:easthardware_pms/domain/repository/payment_repository.dart';
import 'package:easthardware_pms/domain/errors/exceptions.dart';

class PaymentRepositoryImpl implements PaymentRepository {
  PaymentRepositoryImpl(DatabaseHelper? databaseHelper) : _paymentDao = PaymentDao(databaseHelper);

  final PaymentDao _paymentDao;

  @override
  Future<List<Payment>> getAllPayments() async {
    try {
      return await _paymentDao.getAllPayments();
    } catch (e) {
      throw DatabaseException("Failed to fetch payments: $e");
    }
  }

  @override
  Future<void> deletePayment(int id) {
    try {
      return _paymentDao.deletePayment(id);
    } catch (e) {
      throw DatabaseException("Failed to delete payment: $e");
    }
  }

  @override
  Future<Payment?> getPaymentById(int id) {
    try {
      return _paymentDao.getPaymentById(id);
    } catch (e) {
      throw DatabaseException("Failed to fetch payment: $e");
    }
  }

  @override
  Future<Payment> insertPayment(Payment payment) {
    try {
      return _paymentDao.insertPayment(payment);
    } catch (e) {
      throw DatabaseException("Failed to insert payment: $e");
    }
  }

  @override
  Future<Payment> updatePayment(Payment payment) {
    try {
      return _paymentDao.updatePayment(payment);
    } catch (e) {
      throw DatabaseException("Failed to update payment: $e");
    }
  }
}
