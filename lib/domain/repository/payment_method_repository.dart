import 'package:easthardware_pms/data/database/database_helper.dart';
import 'package:easthardware_pms/data/repository/payment_method_repository.dart';
import 'package:easthardware_pms/domain/models/payment_method.dart';

abstract class PaymentMethodRepository {
  factory PaymentMethodRepository(DatabaseHelper? databaseHelper) = PaymentMethodRepositoryImpl;

  Future<List<PaymentMethod>> getAllPaymentMethods();
  Future<PaymentMethod?> getPaymentMethodById(int id);
  Future<PaymentMethod> insertPaymentMethod(PaymentMethod paymentMethod);
  Future<PaymentMethod> updatePaymentMethod(PaymentMethod paymentMethod);
  Future<void> deletePaymentMethod(int id);
}
