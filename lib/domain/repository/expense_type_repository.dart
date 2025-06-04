import 'package:easthardware_pms/data/database/database_helper.dart';
import 'package:easthardware_pms/data/repository/expense_type_repository.dart';
import 'package:easthardware_pms/domain/models/expense_type.dart';

/// ExpenseTypeRepository is an abstract class that defines the contract for
/// repositories that manage expense types.
/// It is part of the domain layer in a clean architecture setup.
/// This class is intended to be implemented by concrete classes that will
/// provide the actual data access logic for expense types.
///
abstract interface class ExpenseTypeRepository {
  factory ExpenseTypeRepository(DatabaseHelper? databaseHelper) = ExpenseTypeRepositoryImpl;

  /// Fetches all expense types.
  ///
  /// Returns a list of [ExpenseType] objects.
  Future<List<ExpenseType>> getAllExpenseTypes();

  /// Fetches an expense type by its ID.
  ///
  /// [id] is the unique identifier of the expense type to fetch.
  /// Returns an [ExpenseType] object if found, or null if not found.
  Future<ExpenseType?> getExpenseTypeById(int id);

  /// Creates a new expense type.
  ///
  /// [expenseType] is the [ExpenseType] object to create.
  /// Returns the created [ExpenseType] object.
  Future<ExpenseType> insertExpenseType(ExpenseType expenseType);

  /// Updates an existing expense type.
  ///
  /// [expenseType] is the [ExpenseType] object to update.
  /// Returns the updated [ExpenseType] object.
  Future<ExpenseType> updateExpenseType(ExpenseType expenseType);

  /// Deletes an expense type by its ID.
  ///
  /// [id] is the unique identifier of the expense type to delete.
  Future<void> deleteExpenseType(int id);
}
