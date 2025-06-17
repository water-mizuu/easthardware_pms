import 'package:easthardware_pms/data/database/dao/categories_dao.dart';
import 'package:easthardware_pms/data/database/database_helper.dart';
import 'package:easthardware_pms/domain/errors/exceptions.dart';
import 'package:easthardware_pms/domain/models/category.dart';
import 'package:easthardware_pms/domain/repository/category_repository.dart';

class CategoryRepositoryImpl implements CategoryRepository {
  CategoryRepositoryImpl(DatabaseHelper? databaseHelper)
      : _categoriesDao = CategoriesDao(databaseHelper);

  final CategoriesDao _categoriesDao;

  @override
  Future<void> deleteCategory(int id) async {
    try {
      return await _categoriesDao.deleteCategory(id);
    } catch (e) {
      throw DatabaseException('Failed to delete category: $e');
    }
  }

  @override
  Future<List<Category>> getAllCategories() async {
    try {
      return await _categoriesDao.getAllCategories();
    } catch (e) {
      throw DatabaseException('Failed to fetch all categories: $e');
    }
  }

  @override
  Future<Category?> getCategoryById(int id) async {
    try {
      return await _categoriesDao.getCategoryById(id);
    } catch (e) {
      throw DatabaseException('Failed to fetch category by ID: $e');
    }
  }

  @override
  Future<Category> insertCategory(Category category) async {
    try {
      return await _categoriesDao.insertCategory(category);
    } catch (e) {
      throw DatabaseException('Failed to insert category: $e');
    }
  }

  @override
  Future<Category> updateCategory(Category category) async {
    try {
      return await _categoriesDao.updateCategory(category);
    } catch (e) {
      throw DatabaseException('Failed to update category: $e');
    }
  }

  @override
  Future<Category?> getCategoryByName(String name) {
    try {
      return _categoriesDao.getCategoryByName(name);
    } catch (e) {
      throw DatabaseException('Failed to fetch category by name: $e');
    }
  }
}
