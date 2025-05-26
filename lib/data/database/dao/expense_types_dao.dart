import 'package:easthardware_pms/data/database/dao/dao_base.dart';
import 'package:easthardware_pms/data/database/database_helper.dart';
import 'package:easthardware_pms/domain/models/expense_type.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

abstract interface class ExpenseTypesDao {
  factory ExpenseTypesDao(DatabaseHelper? databaseHelper) {
    return ExpenseTypesDaoImpl._(databaseHelper);
  }
  Future<List<ExpenseType>> getAllExpenseTypes();
  Future<ExpenseType?> getExpenseTypeById(int id);
  Future<ExpenseType> insertExpenseType(ExpenseType expenseType);
  Future<ExpenseType> updateExpenseType(ExpenseType expenseType);
  Future<void> deleteExpenseType(int id);
}

// This class would implement the ExpenseTypesDao interface
// and provide the actual database operations using a database library.
// For example, using sqflite or any other database library.
// The implementation would include methods to interact with the database
// and perform CRUD operations on the expense types.
final class ExpenseTypesDaoImpl extends DaoBase implements ExpenseTypesDao {
  ExpenseTypesDaoImpl._(super.databaseHelper);

  /// This method retrieves all expense types from the database.
  /// It returns a list of [ExpenseType] objects.
  /// If no expense types are found, it returns an empty list.
  ///
  @override
  Future<List<ExpenseType>> getAllExpenseTypes() async {
    final db = databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('expense_types');
    return List.generate(maps.length, (i) {
      return ExpenseType.fromMap(maps[i]);
    });
  }

  /// This method retrieves a specific expense type by its ID.
  /// It returns an [ExpenseType] object if found, otherwise null.
  @override
  Future<ExpenseType?> getExpenseTypeById(int id) async {
    final db = databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'expense_types',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return ExpenseType.fromMap(maps.first);
    }
    return null;
  }

  /// This method inserts a new expense type into the database.
  /// It takes an [ExpenseType] object as a parameter.
  /// It returns a Future that completes when the operation is done.
  /// If the operation fails, it throws an exception.
  @override
  Future<ExpenseType> insertExpenseType(ExpenseType expenseType) async {
    final db = databaseHelper.database;
    final id = await db.insert(
      'expense_types',
      expenseType.toMap(),
      conflictAlgorithm: ConflictAlgorithm.fail,
    );
    return expenseType.copyWith(id: id);
  }

  /// This method updates an existing expense type in the database.
  /// It takes an [ExpenseType] object as a parameter.
  /// It returns a Future that completes when the operation is done.
  /// If the operation fails, it throws an exception.
  @override
  Future<ExpenseType> updateExpenseType(ExpenseType expenseType) async {
    final db = databaseHelper.database;
    await db.update(
      'expense_types',
      expenseType.toMap(),
      where: 'id = ?',
      whereArgs: [expenseType.id],
    );
    return expenseType;
  }

  /// This method deletes an expense type from the database.
  /// It takes the ID of the expense type as a parameter.
  /// It returns a Future that completes when the operation is done.
  /// If the operation fails, it throws an exception.
  @override
  Future<void> deleteExpenseType(int id) async {
    final db = databaseHelper.database;
    await db.delete(
      'expense_types',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
