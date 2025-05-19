import 'package:easthardware_pms/data/database/dao/payment_methods_dao.dart';
import 'package:easthardware_pms/data/database/database_helper.dart';
import 'package:easthardware_pms/domain/errors/exceptions.dart';
import 'package:easthardware_pms/domain/models/payment_method.dart';
import 'package:easthardware_pms/domain/repository/payment_method_repository.dart';

class PaymentMethodRepositoryImpl implements PaymentMethodRepository {
  PaymentMethodRepositoryImpl(DatabaseHelper? databaseHelper)
      : paymentMethodsDao = PaymentMethodsDao(databaseHelper);

  final PaymentMethodsDao paymentMethodsDao;

  @override
  Future<void> deletePaymentMethod(int id) {
    try {
      return paymentMethodsDao.deletePaymentMethod(id);
    } catch (e) {
      throw DatabaseException('Failed to delete payment method: $e');
    }
  }

  @override
  Future<List<PaymentMethod>> getAllPaymentMethods() {
    try {
      return paymentMethodsDao.getAllPaymentMethods();
    } catch (e) {
      throw DatabaseException('Failed to fetch all payment methods: $e');
    }
  }

  @override
  Future<PaymentMethod?> getPaymentMethodById(int id) {
    if (id <= 0) {
      throw ArgumentError('Invalid payment method ID');
    }
    try {
      return paymentMethodsDao.getPaymentMethodById(id);
    } catch (e) {
      throw DatabaseException('Failed to fetch payment method by ID: $e');
    }
  }

  @override
  Future<PaymentMethod> insertPaymentMethod(PaymentMethod paymentMethod) {
    try {
      return paymentMethodsDao.insertPaymentMethod(paymentMethod);
    } catch (e) {
      throw DatabaseException('Failed to insert payment method: $e');
    }
  }

  @override
  Future<PaymentMethod> updatePaymentMethod(PaymentMethod paymentMethod) {
    try {
      return paymentMethodsDao.updatePaymentMethod(paymentMethod);
    } catch (e) {
      throw DatabaseException('Failed to update payment method: $e');
    }
  }
}
