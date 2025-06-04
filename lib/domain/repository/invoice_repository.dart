import 'package:easthardware_pms/data/database/database_helper.dart';
import 'package:easthardware_pms/data/repository/invoice_repository.dart';
import 'package:easthardware_pms/domain/models/invoice.dart';

abstract class InvoiceRepository {
  factory InvoiceRepository(DatabaseHelper? databaseHelper) = InvoiceRepositoryImpl;

  Future<List<Invoice>> getAllInvoices();
  Future<Invoice?> getInvoiceById(int id);
  Future<Invoice> insertInvoice(Invoice invoice);
  Future<Invoice> updateInvoice(Invoice invoice);
  Future<void> deleteInvoice(Invoice invoice);
  Future<List<Invoice>> getInvoicesByCustomerName(String customerName);
  Future<List<Invoice>> getInvoicesByDateRange(DateTime startDate, DateTime endDate);
  Future<List<Invoice>> getInvoicesByPaymentMethod(String paymentMethod);
  Future<List<Invoice>> getInvoicesByAmountDue(double minAmount, double maxAmount);
  Future<List<Invoice>> getInvoicesByCreatorId(int creatorId);
  Future<List<Invoice>> getInvoicesByProductIds(List<int> productIds);
  Future<List<Invoice>> getInvoiceByProductCategory(int categoryId);
  Future<double> getTotalAmountDue();
  Future<double> getTotalAmountPaid();
  Future<int> getPaidInvoiceCount();
  Future<int> getUnpaidInvoiceCount();
  Future<int> getTotalInvoiceCount();
}
