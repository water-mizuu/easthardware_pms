import 'package:easthardware_pms/data/database/dao/dao_base.dart';
import 'package:flutter/foundation.dart';

base class MetadataDao extends DaoBase {
  const MetadataDao(super.databaseHelper);

  Future<int> getRecordCount() async {
    final db = databaseHelper.database;
    final allTables = await db.query(
      'sqlite_master',
      where: 'type=?',
      whereArgs: ['table'],
      columns: ['name'],
    );

    var count = 0;
    for (final {"name": tableName as String} in allTables) {
      if (tableName.startsWith("sqlite")) continue;

      if (await db.rawQuery('SELECT COUNT(*) AS count FROM $tableName')
          case [{"count": final int rowCount}]) {
        count += rowCount;
      }
    }

    if (kDebugMode) {
      print(allTables);
    }

    return count;
  }
}
