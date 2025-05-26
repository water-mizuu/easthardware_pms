import 'package:easthardware_pms/data/database/dao/invoice_products_dao.dart';
import 'package:easthardware_pms/data/database/database_helper.dart';
import 'package:easthardware_pms/data/repository/product_repository.dart';
import 'package:easthardware_pms/domain/enums/enums.dart';
import 'package:easthardware_pms/domain/errors/exceptions.dart';
import 'package:easthardware_pms/domain/models/invoice_product.dart';
import 'package:easthardware_pms/domain/models/product.dart';
import 'package:easthardware_pms/domain/repository/invoice_product_repository.dart';

class InvoiceProductRepositoryImpl implements InvoiceProductRepository {
  InvoiceProductRepositoryImpl(DatabaseHelper? databaseHelper)
      : _invoiceProductsDao = InvoiceProductsDao(databaseHelper),
        _productRepository = ProductRepositoryImpl(databaseHelper);

  final InvoiceProductsDao _invoiceProductsDao;
  final ProductRepositoryImpl _productRepository;

  @override
  Future<InvoiceProduct> createInvoiceProduct(InvoiceProduct invoiceProduct) {
    try {
      return _invoiceProductsDao.insertInvoiceProduct(invoiceProduct);
    } catch (e) {
      throw DatabaseException('Failed to create invoice product: $e');
    }
  }

  @override
  Future<void> deleteInvoiceProduct(int id) async {
    if (id <= 0) {
      throw ArgumentError('Invalid invoice product ID');
    }
    try {
      return await _invoiceProductsDao.deleteInvoiceProduct(id);
    } catch (e) {
      throw DatabaseException('Failed to delete invoice product: $e');
    }
  }

  @override
  Future<List<InvoiceProduct>> getAllInvoiceProducts() async {
    try {
      return await _invoiceProductsDao.getAllInvoiceProducts();
    } catch (e) {
      throw DatabaseException('Failed to fetch all invoice products: $e');
    }
  }

  @override
  Future<InvoiceProduct?> getInvoiceProductById(int id) async {
    if (id <= 0) {
      throw ArgumentError('Invalid invoice product ID');
    }
    try {
      return await _invoiceProductsDao.getInvoiceProductById(id);
    } catch (e) {
      throw DatabaseException('Failed to fetch invoice product by ID: $e');
    }
  }

  @override
  Future<InvoiceProduct> updateInvoiceProduct(InvoiceProduct invoiceProduct) async {
    _validateInvoiceProduct(invoiceProduct);
    try {
      return await _invoiceProductsDao.updateInvoiceProduct(invoiceProduct);
    } catch (e) {
      throw DatabaseException('Failed to update invoice product: $e');
    }
  }

  void _validateInvoiceProduct(InvoiceProduct invoiceProduct) async {
    ProductRepositoryImpl productRepository = _productRepository;

    if (invoiceProduct.quantity <= 0) {
      throw ArgumentError('Quantity should be greater than 0');
    }
    Product? product = await productRepository.getProductById(invoiceProduct.productId);

    if (invoiceProduct.quantity > product!.quantity) {
      throw ArgumentError('Quantity should be less than or equal to the available quantity');
    }

    if (invoiceProduct.discount! < 0) {
      throw ArgumentError("Discount can not be negative");
    }
    if (100 < invoiceProduct.discount! && invoiceProduct.discountType == DiscountType.percentage) {
      throw ArgumentError("Discount can not be greater than 100%");
    }
  }

  @override
  Future<List<InvoiceProduct?>> getInvoiceProductsByInvoiceId(int invoiceId) async {
    if (invoiceId <= 0) {
      throw ArgumentError('Invalid invoice ID');
    }
    try {
      return await _invoiceProductsDao.getInvoiceProductsByInvoiceId(invoiceId);
    } catch (e) {
      throw DatabaseException('Failed to fetch invoice products by invoice ID: $e');
    }
  }
}
