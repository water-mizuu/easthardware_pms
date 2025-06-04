import 'package:easthardware_pms/data/database/database_helper.dart';
import 'package:easthardware_pms/data/repository/category_repository.dart';
import 'package:easthardware_pms/domain/models/category.dart';

abstract class CategoryRepository {
  factory CategoryRepository(DatabaseHelper? databaseHelper) = CategoryRepositoryImpl;

  Future<List<Category>> getAllCategories();
  Future<Category?> getCategoryById(int id);

  Future<Category> insertCategory(Category category);
  Future<Category> updateCategory(Category category);
  Future<void> deleteCategory(int id);
}
