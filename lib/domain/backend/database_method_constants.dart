/// Constants for database method names used in the server proxy communication.
///
/// This file centralizes all method names to prevent typos and make maintenance easier.
/// These constants are used for communication between the DatabaseServerProxy and
/// the server database handler.
library;

/// Standard database operation method names
abstract class DatabaseMethods {
  // Basic CRUD operations
  static const String delete = 'delete';
  static const String execute = 'execute';
  static const String insert = 'insert';
  static const String query = 'query';
  static const String rawDelete = 'rawDelete';
  static const String rawInsert = 'rawInsert';
  static const String rawQuery = 'rawQuery';
  static const String rawUpdate = 'rawUpdate';
  static const String update = 'update';

  // Cursor operations
  static const String queryCursor = 'queryCursor';
  static const String rawQueryCursor = 'rawQueryCursor';

  // Batch operations
  static const String batchCommit = 'batch.commit';
  static const String batchApply = 'batch.apply';
}

/// Transaction-related method names
abstract class TransactionMethods {
  // Transaction lifecycle - read transactions
  static const String readTransactionBegin = 'readTransaction.begin';
  static const String readTransactionEnd = 'readTransaction.end';
  static const String readTransactionRollback = 'readTransaction.rollback';

  // Transaction lifecycle - write transactions
  static const String transactionBegin = 'transaction.begin';
  static const String transactionCommit = 'transaction.commit';
  static const String transactionRollback = 'transaction.rollback';

  // Transaction operations
  static const String transactionDelete = 'transaction.delete';
  static const String transactionExecute = 'transaction.execute';
  static const String transactionInsert = 'transaction.insert';
  static const String transactionQuery = 'transaction.query';
  static const String transactionRawDelete = 'transaction.rawDelete';
  static const String transactionRawInsert = 'transaction.rawInsert';
  static const String transactionRawQuery = 'transaction.rawQuery';
  static const String transactionRawUpdate = 'transaction.rawUpdate';
  static const String transactionUpdate = 'transaction.update';

  // Transaction cursor operations
  static const String transactionQueryCursor = 'transaction.queryCursor';
  static const String transactionRawQueryCursor = 'transaction.rawQueryCursor';

  // Transaction batch operations
  static const String transactionBatchCommit = 'transaction.batch.commit';
  static const String transactionBatchApply = 'transaction.batch.apply';
}

/// Cursor-related method names
abstract class CursorMethods {
  static const String moveNext = 'cursor.moveNext';
  static const String close = 'cursor.close';
}
