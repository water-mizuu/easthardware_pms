import 'package:easthardware_pms/data/database/database_helper.dart';

abstract base class DaoBase {
  final DatabaseHelper? _databaseHelper;

  const DaoBase(this._databaseHelper);

  DatabaseHelper get databaseHelper {
    if (_databaseHelper == null) {
      throw StateError("Tried to access ${super.runtimeType} without "
          "the database helper being assigned.");
    }
    return _databaseHelper;
  }
}
