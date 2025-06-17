import 'package:easthardware_pms/data/database/database_helper.dart';
import 'package:easthardware_pms/data/repository/invoice_product_repository.dart';
import 'package:easthardware_pms/domain/models/invoice_product.dart';

abstract class InvoiceProductRepository {
  factory InvoiceProductRepository(DatabaseHelper? databaseHelper) = InvoiceProductRepositoryImpl;

  Future<List<InvoiceProduct>> fetchAllInvoiceProducts();
  Future<InvoiceProduct?> fetchInvoiceProductById(int id);
  Future<List<InvoiceProduct>> fetchInvoiceProductsByInvoice(int invoiceId);
  Future<InvoiceProduct> insertInvoiceProduct(InvoiceProduct invoiceProduct);
  Future<void> updateInvoiceProduct(InvoiceProduct invoiceProduct);
  Future<void> deleteInvoiceProduct(int id);
}
