import 'package:easthardware_pms/data/database/dao/dao_base.dart';
import 'package:easthardware_pms/data/database/database_helper.dart';
import 'package:easthardware_pms/domain/models/invoice.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

abstract interface class InvoicesDao {
  factory InvoicesDao(DatabaseHelper? databaseHelper) = InvoicesDaoImpl._;

  Future<List<Invoice>> getAllInvoices();
  Future<Invoice?> getInvoiceById(int id);
  Future<Invoice?> getInvoiceByUid(String uid);
  Future<Invoice> insertInvoice(Invoice invoice);
  Future<Invoice> updateInvoice(Invoice invoice);
  Future<void> deleteInvoice(int id);
  Future<List<Invoice>> getInvoicesByCustomerName(String customerName);
  Future<List<Invoice>> getInvoicesByDateRange(DateTime startDate, DateTime endDate);
  Future<List<Invoice>> getInvoicesByPaymentMethod(String paymentMethod);
  Future<List<Invoice>> getInvoicesByAmountDue(double minAmount, double maxAmount);
  Future<List<Invoice>> getInvoicesByCreatorId(int creatorId);
  Future<List<Invoice>> getInvoicesByProductIds(List<int> productIds);
  Future<List<Invoice>> getInvoiceByProductCategory(int categoryId);
  Future<Invoice?> getLatestInvoiceOfProduct(int productId);
  Future<int> getRecentInvoiceCountOfProduct(int productId);
  Future<int> getPaidInvoiceCount();
  Future<int> getUnpaidInvoiceCount();
  Future<double> getTotalAmountPaid();
  Future<double> getTotalAmountDue();
}

/// The [InvoicesDaoImpl] class implements the [InvoicesDao] interface
/// and provides methods to interact with the invoices table in the database.
/// It uses the [DatabaseHelper] class to get a reference to the database.
///
final class InvoicesDaoImpl extends DaoBase implements InvoicesDao {
  InvoicesDaoImpl._(super.databaseHelper);

  /// Returns a list of all invoices in the database.
  ///
  @override
  Future<List<Invoice>> getAllInvoices() async {
    final db = databaseHelper.database;
    print(#B);
    final maps = await db.query('invoices');
    print(#C);
    return List.generate(maps.length, (i) {
      return Invoice.fromMap(maps[i]);
    });
  }

  /// Returns an invoice by its ID.
  /// If no invoice is found, returns null.
  ///
  @override
  Future<Invoice?> getInvoiceById(int id) async {
    final db = databaseHelper.database;
    final maps = await db.query(
      'invoices',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Invoice.fromMap(maps.first);
    }
    return null;
  }

  /// Inserts a new invoice into the database.
  @override
  Future<Invoice> insertInvoice(Invoice invoice) async {
    final db = databaseHelper.database;
    final id = await db.insert(
      'invoices',
      invoice.toMap(),
      conflictAlgorithm: ConflictAlgorithm.fail,
    );
    return invoice.copyWith(id: id);
  }

  /// Updates an existing invoice in the database.
  @override
  Future<Invoice> updateInvoice(Invoice invoice) async {
    final db = databaseHelper.database;
    await db.update(
      'invoices',
      invoice.toMap(),
      where: 'id = ?',
      whereArgs: [invoice.id],
    );
    return invoice;
  }

  @override
  Future<void> deleteInvoice(int id) async {
    final db = databaseHelper.database;
    await db.delete(
      'invoices',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Returns a list of invoices by date range.
  /// If no invoices are found, returns an empty list.
  ///
  @override
  Future<List<Invoice>> getInvoicesByDateRange(DateTime startDate, DateTime endDate) async {
    final db = databaseHelper.database;
    final maps = await db.query(
      'invoices',
      where: 'invoice_date BETWEEN ? AND ?',
      whereArgs: [startDate.toIso8601String(), endDate.toIso8601String()],
    );
    return List.generate(maps.length, (i) {
      return Invoice.fromMap(maps[i]);
    });
  }

  /// Returns a list of invoices by payment method.
  /// If no invoices are found, returns an empty list.
  ///
  @override
  Future<List<Invoice>> getInvoicesByPaymentMethod(String paymentMethod) async {
    final db = databaseHelper.database;
    final maps = await db.query(
      'invoices',
      where: 'payment_method = ?',
      whereArgs: [paymentMethod],
    );
    return List.generate(maps.length, (i) {
      return Invoice.fromMap(maps[i]);
    });
  }

  /// Returns a list of invoices by total amount.
  /// If no invoices are found, returns an empty list.
  ///
  @override
  Future<List<Invoice>> getInvoicesByAmountDue(double minAmount, double maxAmount) async {
    final db = databaseHelper.database;
    final maps = await db.query(
      'invoices',
      where: 'amount_due BETWEEN ? AND ?',
      whereArgs: [minAmount, maxAmount],
    );
    return List.generate(maps.length, (i) {
      return Invoice.fromMap(maps[i]);
    });
  }

  /// Returns a list of invoices by created by user ID.
  /// If no invoices are found, returns an empty list.
  ///
  @override
  Future<List<Invoice>> getInvoicesByCreatorId(int createdBy) async {
    final db = databaseHelper.database;
    final maps = await db.query(
      'invoices',
      where: 'creator_id = ?',
      whereArgs: [createdBy],
    );
    return List.generate(maps.length, (i) {
      return Invoice.fromMap(maps[i]);
    });
  }

  /// Returns a list of invoices by product IDs.
  /// If no invoices are found, returns an empty list.
  ///

  @override
  Future<List<Invoice>> getInvoicesByProductIds(List<int> productIds) async {
    final db = databaseHelper.database;
    final maps = await db.rawQuery(
      'SELECT DISTINCT invoices.* FROM invoices '
      'JOIN invoice_products ON invoices.id = invoice_products.invoice_id '
      'WHERE invoice_products.product_id IN (${productIds.join(',')})',
    );
    return List.generate(maps.length, (i) {
      return Invoice.fromMap(maps[i]);
    });
  }

  /// Returns a list of invoices by product category ID.
  /// If no invoices are found, returns an empty list.
  ///
  @override
  Future<List<Invoice>> getInvoiceByProductCategory(int categoryId) async {
    final db = databaseHelper.database;
    final maps = await db.rawQuery(
      'SELECT DISTINCT invoices.* FROM invoices '
      'JOIN invoice_products ON invoices.id = invoice_products.invoice_id '
      'JOIN products ON invoice_products.product_id = products.id '
      'WHERE products.category_id = ?',
      [categoryId],
    );
    return List.generate(maps.length, (i) {
      return Invoice.fromMap(maps[i]);
    });
  }

  /// Returns a list of invoices by customer name
  /// If no invoices are found, returns an empty list.
  ///
  @override
  Future<List<Invoice>> getInvoicesByCustomerName(String customerName) async {
    final db = databaseHelper.database;
    final maps = await db.query('invoices', where: 'customer_name = ?', whereArgs: [customerName]);
    return List.generate(maps.length, (i) {
      return Invoice.fromMap(maps[i]);
    });
  }

  @override
  Future<Invoice?> getLatestInvoiceOfProduct(int productId) async {
    final db = databaseHelper.database;
    final maps = await db.rawQuery(
      'SELECT DISTINCT invoices.* FROM invoices '
      'JOIN invoice_products ON invoices.id = invoice_products.invoice_id '
      'WHERE invoice_products.product_id = ? '
      'ORDER BY invoice_date DESC LIMIT 1',
      [productId],
    );
    if (maps.isNotEmpty) {
      return Invoice.fromMap(maps.first);
    }
    return null;
  }

  @override
  Future<int> getRecentInvoiceCountOfProduct(int productId) async {
    final db = databaseHelper.database;
    final maps = await db.rawQuery(
      'SELECT COUNT(*) as count FROM invoices '
      'JOIN invoice_products ON invoices.id = invoice_products.invoice_id '
      'WHERE invoice_products.product_id = ?',
      [productId],
    );
    if (maps.isNotEmpty) {
      return maps.first['count'] as int;
    }
    return 0;
  }

  @override
  Future<int> getPaidInvoiceCount() async {
    final db = databaseHelper.database;
    final maps = await db.query(
      'invoices',
      where: 'amount_paid > ?',
      whereArgs: [0],
    );
    return maps.length;
  }

  @override
  Future<double> getTotalAmountDue() async {
    final db = databaseHelper.database;
    final maps = await db.rawQuery(
      'SELECT SUM(amount_due) as total FROM invoices',
    );
    if (maps.isNotEmpty) {
      return maps.first['total'] as double;
    }
    return 0.0;
  }

  @override
  Future<double> getTotalAmountPaid() async {
    final db = databaseHelper.database;
    final maps = await db.rawQuery(
      'SELECT SUM(amount_paid) as total FROM invoices',
    );
    if (maps.isNotEmpty) {
      return maps.first['total'] as double;
    }
    return 0.0;
  }

  @override
  Future<int> getUnpaidInvoiceCount() async {
    final db = databaseHelper.database;
    final maps = await db.query(
      'invoices',
      where: 'amount_paid = ?',
      whereArgs: [0],
    );
    return maps.length;
  }

  @override
  Future<Invoice?> getInvoiceByUid(String uid) async {
    final db = databaseHelper.database;
    final maps = await db.query(
      'invoices',
      where: 'uid = ?',
      whereArgs: [uid],
    );
    if (maps.isNotEmpty) {
      return Invoice.fromMap(maps.first);
    }
    return null;
  }
}
