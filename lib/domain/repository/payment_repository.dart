import 'package:easthardware_pms/data/repository/payment_repository.dart';
import 'package:easthardware_pms/data/database/database_helper.dart';
import 'package:easthardware_pms/domain/models/payment.dart';

abstract interface class PaymentRepository {
  factory PaymentRepository(DatabaseHelper? databaseHelper) = PaymentRepositoryImpl;
  Future<List<Payment>> getAllPayments();
  Future<Payment?> getPaymentById(int id);
  Future<Payment> insertPayment(Payment payment);
  Future<Payment> updatePayment(Payment payment);
  Future<void> deletePayment(int id);
}
