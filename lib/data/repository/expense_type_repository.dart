import 'package:easthardware_pms/data/database/dao/expense_types_dao.dart';
import 'package:easthardware_pms/data/database/database_helper.dart';
import 'package:easthardware_pms/domain/errors/exceptions.dart';
import 'package:easthardware_pms/domain/models/expense_type.dart';
import 'package:easthardware_pms/domain/repository/expense_type_repository.dart';

class ExpenseTypeRepositoryImpl implements ExpenseTypeRepository {
  ExpenseTypeRepositoryImpl(DatabaseHelper? databaseHelper)
      : _expenseTypeDao = ExpenseTypesDao(databaseHelper);

  final ExpenseTypesDao _expenseTypeDao;

  @override
  Future<void> deleteExpenseType(int id) async {
    if (id <= 0) {
      throw ArgumentError('Invalid expense type ID');
    }
    try {
      await _expenseTypeDao.deleteExpenseType(id);
    } catch (e) {
      throw DatabaseException('Failed to delete expense type: $e');
    }
  }

  @override
  Future<List<ExpenseType>> getAllExpenseTypes() async {
    try {
      return await _expenseTypeDao.getAllExpenseTypes();
    } catch (e) {
      throw DatabaseException('Failed to fetch all expense types: $e');
    }
  }

  @override
  Future<ExpenseType?> getExpenseTypeById(int id) async {
    if (id <= 0) {
      throw ArgumentError('Invalid expense type ID');
    }
    try {
      return await _expenseTypeDao.getExpenseTypeById(id);
    } catch (e) {
      throw DatabaseException('Failed to fetch expense type by ID: $e');
    }
  }

  @override
  Future<ExpenseType> insertExpenseType(ExpenseType expenseType) async {
    _validateExpenseType(expenseType);
    try {
      return await _expenseTypeDao.insertExpenseType(expenseType);
    } catch (e) {
      throw DatabaseException('Failed to insert expense type: $e');
    }
  }

  @override
  Future<ExpenseType> updateExpenseType(ExpenseType expenseType) async {
    _validateExpenseType(expenseType);
    try {
      return await _expenseTypeDao.updateExpenseType(expenseType);
    } catch (e) {
      throw DatabaseException('Failed to update expense type: $e');
    }
  }

  void _validateExpenseType(ExpenseType expenseType) {
    if (expenseType.name.isEmpty) {
      throw ArgumentError('Expense type name cannot be empty');
    }
  }
}
