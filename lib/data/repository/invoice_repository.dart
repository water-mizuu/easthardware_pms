import 'package:easthardware_pms/data/database/dao/invoices_dao.dart';
import 'package:easthardware_pms/data/database/database_helper.dart';
import 'package:easthardware_pms/domain/models/invoice.dart';
import 'package:easthardware_pms/domain/repository/invoice_repository.dart';

class InvoiceRepositoryImpl implements InvoiceRepository {
  InvoiceRepositoryImpl(DatabaseHelper? databaseHelper) //
      : _invoicesDao = InvoicesDao(databaseHelper);

  final InvoicesDao _invoicesDao;

  @override
  Future<void> deleteInvoice(Invoice invoice) async {
    try {
      return await _invoicesDao.deleteInvoice(invoice.id!);
    } catch (e) {
      throw Exception('Failed to delete invoice: $e');
    }
  }

  @override
  Future<List<Invoice>> getAllInvoices() async {
    try {
      return await _invoicesDao.getAllInvoices();
    } catch (e) {
      throw Exception('Failed to fetch all invoices: $e');
    }
  }

  @override
  Future<Invoice?> getInvoiceById(int id) async {
    if (id <= 0) {
      throw ArgumentError('Invalid invoice ID');
    }
    try {
      return await _invoicesDao.getInvoiceById(id);
    } catch (e) {
      throw Exception('Failed to fetch invoice by ID: $e');
    }
  }

  @override
  Future<List<Invoice>> getInvoiceByProductCategory(int categoryId) async {
    if (categoryId <= 0) {
      throw ArgumentError('Invalid category ID');
    }
    try {
      return await _invoicesDao.getInvoiceByProductCategory(categoryId);
    } catch (e) {
      throw Exception('Failed to fetch invoices by product category: $e');
    }
  }

  @override
  Future<List<Invoice>> getInvoicesByAmountDue(double minAmount, double maxAmount) async {
    if (minAmount < 0 || maxAmount < 0) {
      throw ArgumentError('Invalid amount range');
    }
    try {
      return await _invoicesDao.getInvoicesByAmountDue(minAmount, maxAmount);
    } catch (e) {
      throw Exception('Failed to fetch invoices by amount due: $e');
    }
  }

  @override
  Future<List<Invoice>> getInvoicesByCreatorId(int creatorId) async {
    if (creatorId <= 0) {
      throw ArgumentError('Invalid creator ID');
    }
    try {
      return await _invoicesDao.getInvoicesByCreatorId(creatorId);
    } catch (e) {
      throw Exception('Failed to fetch invoices by creator ID: $e');
    }
  }

  @override
  Future<List<Invoice>> getInvoicesByCustomerName(String customerName) async {
    if (customerName.isEmpty) {
      throw ArgumentError('Invalid customer name');
    }
    try {
      return await _invoicesDao.getInvoicesByCustomerName(customerName);
    } catch (e) {
      throw Exception('Failed to fetch invoices by customer name: $e');
    }
  }

  @override
  Future<List<Invoice>> getInvoicesByDateRange(DateTime startDate, DateTime endDate) async {
    if (startDate.isAfter(endDate)) {
      throw ArgumentError('Invalid date range');
    }
    try {
      return await _invoicesDao.getInvoicesByDateRange(startDate, endDate);
    } catch (e) {
      throw Exception('Failed to fetch invoices by date range: $e');
    }
  }

  @override
  Future<List<Invoice>> getInvoicesByPaymentMethod(String paymentMethod) async {
    if (paymentMethod.isEmpty) {
      throw ArgumentError('Invalid payment method');
    }
    try {
      return await _invoicesDao.getInvoicesByPaymentMethod(paymentMethod);
    } catch (e) {
      throw Exception('Failed to fetch invoices by payment method: $e');
    }
  }

  @override
  Future<List<Invoice>> getInvoicesByProductIds(List<int> productIds) async {
    if (productIds.isEmpty) {
      throw ArgumentError('Invalid product IDs');
    }
    try {
      return await _invoicesDao.getInvoicesByProductIds(productIds);
    } catch (e) {
      throw Exception('Failed to fetch invoices by product IDs: $e');
    }
  }

  @override
  Future<int> getPaidInvoiceCount() async {
    try {
      return await _invoicesDao.getPaidInvoiceCount();
    } catch (e) {
      throw Exception('Failed to fetch paid invoice count: $e');
    }
  }

  @override
  Future<double> getTotalAmountDue() async {
    try {
      return await _invoicesDao.getTotalAmountDue();
    } catch (e) {
      throw Exception('Failed to fetch total amount due: $e');
    }
  }

  @override
  Future<double> getTotalAmountPaid() async {
    try {
      return await _invoicesDao.getTotalAmountPaid();
    } catch (e) {
      throw Exception('Failed to fetch total amount paid: $e');
    }
  }

  @override
  Future<int> getTotalInvoiceCount() async {
    try {
      return await _invoicesDao.getAllInvoices().then((invoices) => invoices.length);
    } catch (e) {
      throw Exception('Failed to fetch total invoice count: $e');
    }
  }

  @override
  Future<int> getUnpaidInvoiceCount() async {
    try {
      return await _invoicesDao.getUnpaidInvoiceCount();
    } catch (e) {
      throw Exception('Failed to fetch unpaid invoice count: $e');
    }
  }

  @override
  Future<Invoice> insertInvoice(Invoice invoice) async {
    try {
      return await _invoicesDao.insertInvoice(invoice);
    } catch (e) {
      throw Exception('Failed to insert invoice: $e');
    }
  }

  @override
  Future<Invoice> updateInvoice(Invoice invoice) async {
    try {
      return await _invoicesDao.updateInvoice(invoice);
    } catch (e) {
      throw Exception('Failed to update invoice: $e');
    }
  }
}
