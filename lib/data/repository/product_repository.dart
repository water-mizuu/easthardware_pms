import 'package:easthardware_pms/data/database/dao/products_dao.dart';
import 'package:easthardware_pms/data/database/database_helper.dart';
import 'package:easthardware_pms/domain/errors/exceptions.dart';
import 'package:easthardware_pms/domain/models/product.dart';
import 'package:easthardware_pms/domain/repository/product_repository.dart';

class ProductRepositoryImpl implements ProductRepository {
  ProductRepositoryImpl(DatabaseHelper? databaseHelper)
      : _productsDao = ProductsDao(databaseHelper);

  final ProductsDao _productsDao;

  @override
  Future<void> deleteProduct(int id) {
    try {
      return _productsDao.deleteProduct(id);
    } catch (e) {
      throw DatabaseException("Failed to delete product: $e");
    }
  }

  @override
  Future<List<Product>> getAllProducts() async {
    try {
      final products = await _productsDao.getAllProducts();

      return products;
    } catch (e) {
      throw DatabaseException("Failed to fetch products: $e");
    }
  }

  @override
  Future<Product?> getProductById(int id) async {
    try {
      return await _productsDao.getProductById(id);
    } catch (e) {
      throw DatabaseException("Failed to fetch product: $e");
    }
  }

  @override
  Future<Product> insertProduct(Product product) async {
    try {
      return await _productsDao.insertProduct(product);
    } catch (e) {
      throw DatabaseException("Failed to insert product: $e");
    }
  }

  @override
  Future<Product> updateProduct(Product product) {
    try {
      return _productsDao.updateProduct(product);
    } catch (e) {
      throw DatabaseException("Failed to update product: $e");
    }
  }

  @override
  Future<List<Product>> getDeadStockProducts() {
    try {
      return _productsDao.getDeadStockProducts();
    } catch (e) {
      throw DatabaseException("Failed to fetch dead stock products: $e");
    }
  }

  @override
  Future<List<Product>> getFastMovingProducts() {
    try {
      return _productsDao.getFastMovingProducts();
    } catch (e) {
      throw DatabaseException("Failed to fetch fast moving products: $e");
    }
  }

  @override
  Future<List<Product>> getLowStockProducts() {
    try {
      return _productsDao.getLowStockProducts();
    } catch (e) {
      throw DatabaseException("Failed to fetch low stock products: $e");
    }
  }

  @override
  Future<List<Product>> getProductsByCategoryId(int categoryId) async {
    try {
      return _productsDao.getProductsByCategoryId(categoryId);
    } catch (e) {
      throw DatabaseException("Failed to fetch products by category ID: $e");
    }
  }

  @override
  Future<Product> updateProductStock(int id, double stock) async {
    try {
      final product = await _productsDao.getProductById(id);
      if (product == null) {
        throw DatabaseException("Product with ID $id not found");
      }
      final updatedQuantity = product.quantity + stock;
      if (updatedQuantity < 0) {
        throw DatabaseException("Insufficient stock for product ID $id");
      }
      final updatedProduct = product.copyWith(quantity: updatedQuantity);
      return await _productsDao.updateProduct(updatedProduct);
    } catch (e) {
      throw DatabaseException("Failed to update product stock: $e");
    }
  }
}
