import 'package:easthardware_pms/data/database/dao/dao_base.dart';
import 'package:easthardware_pms/data/database/database_helper.dart';
import 'package:easthardware_pms/data/database/tables/products_table.dart';
import 'package:easthardware_pms/data/database/views/product_flags_view.dart';
import 'package:easthardware_pms/domain/constants/debug_constants.dart';
import 'package:easthardware_pms/domain/models/product.dart';
import 'package:easthardware_pms/utils/boxed.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

abstract interface class ProductsDao {
  factory ProductsDao(DatabaseHelper? databaseHelper) {
    return ProductsDaoImpl._(databaseHelper);
  }

  Future<List<Product>> getAllProducts();
  Future<Product?> getProductById(int id);
  Future<Product> insertProduct(Product product);
  Future<Product> updateProduct(Product product);
  Future<void> deleteProduct(int id);
  Future<List<Product>> getProductsByCategoryId(int categoryId);
  Future<List<Product>> getProductsByCreatorId(int creatorId);
}

final class ProductsDaoImpl extends DaoBase implements ProductsDao {
  const ProductsDaoImpl._(super.databaseHelper);

  @override
  Future<void> deleteProduct(int id) async {
    final database = databaseHelper.database;
    await database.delete(
      ProductsTable.PRODUCTS_TABLE_NAME,
      where: '${ProductsTable.PRODUCTS_ID} = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<List<Product>> getAllProducts() async {
    final database = databaseHelper.database;
    final queryResults = await database.query(ProductFlagsView.PRODUCT_STATUS_VIEW_TABLE);

    return List.generate(queryResults.length, (i) {
      return Product.fromMap(queryResults[i]);
    });
  }

  @override
  Future<Product?> getProductById(int id) async {
    final database = databaseHelper.database;
    final queryResults = await database.query(
      ProductsTable.PRODUCTS_TABLE_NAME,
      where: '${ProductsTable.PRODUCTS_ID} = ?',
      whereArgs: [id],
    );

    try {
      final json = queryResults.single;

      return Product.fromMap(json);
    } on StateError {
      if (isDebugMode) {
        printBoxed("Found duplicate products for id $id!");
      }
      return null;
    }
  }

  @override
  Future<Product> insertProduct(Product product) async {
    final database = databaseHelper.database;
    final id = await database.insert(
      ProductsTable.PRODUCTS_TABLE_NAME,
      product.toMap(),
      conflictAlgorithm: ConflictAlgorithm.fail,
    );

    return product.copyWith(id: id);
  }

  @override
  Future<Product> updateProduct(Product product) async {
    final database = databaseHelper.database;
    final affected = await database.update(
      ProductsTable.PRODUCTS_TABLE_NAME,
      product.toMap(),
      where: '${ProductsTable.PRODUCTS_ID} = ?',
      whereArgs: [product.id],
    );

    assert(affected == 1, "This should only update one row.");

    return product;
  }

  @override
  Future<List<Product>> getProductsByCategoryId(int categoryId) async {
    final database = databaseHelper.database;
    final res = await database.query(
      ProductsTable.PRODUCTS_TABLE_NAME,
      where: '${ProductsTable.PRODUCTS_CATEGORY} = ?',
      whereArgs: [categoryId],
    );
    return res.map(Product.fromMap).toList();
  }

  @override
  Future<List<Product>> getProductsByCreatorId(int creatorId) async {
    final database = databaseHelper.database;
    final res = await database.query(
      ProductsTable.PRODUCTS_TABLE_NAME,
      where: '${ProductsTable.PRODUCTS_CREATOR_ID} = ?',
      whereArgs: [creatorId],
    );
    return res.map(Product.fromMap).toList();
  }
}
