import 'package:easthardware_pms/data/database/database_server_proxy.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// database_helper.dart
/// This file contains the DatabaseHelper class
///
/// The DatabaseHelper class shall be responsible for creating the tables on creating, initializing, and upgrading the SQLite database.
///
/// Any data manipulation functions should be created in DAOs respective to entities.

abstract base class DatabaseHelper {
  DatabaseHelper([this._database]);

  final Database? _database;
  Database get database => _database!;
}

final class ServerDatabaseHelper extends DatabaseHelper {
  ServerDatabaseHelper(Server server) : super(DatabaseServerProxy(server));
}
