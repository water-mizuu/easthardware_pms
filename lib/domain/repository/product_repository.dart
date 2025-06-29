import 'package:easthardware_pms/data/database/database_helper.dart';
import 'package:easthardware_pms/data/repository/product_repository.dart';
import 'package:easthardware_pms/domain/models/product.dart';

abstract interface class ProductRepository {
  factory ProductRepository(DatabaseHelper? databaseHelper) = ProductRepositoryImpl;

  Future<List<Product>> getAllProducts();
  Future<Product?> getProductById(int id);
  Future<Product> insertProduct(Product product);
  Future<Product> updateProduct(Product product);
  Future<Product> updateProductStock(int id, double stock);
  Future<void> deleteProduct(int id);
  Future<List<Product>> getProductsByCategoryId(int categoryId);
}
