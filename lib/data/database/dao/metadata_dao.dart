import 'package:easthardware_pms/data/database/dao/dao_base.dart';
import 'package:easthardware_pms/domain/constants/debug_constants.dart';
import 'package:easthardware_pms/utils/boxed.dart';

base class MetadataDao extends DaoBase {
  const MetadataDao(super.databaseHelper);

  Future<List<(String, List<Map<String, dynamic>>)>> getAllRecords() async {
    final db = databaseHelper.database;
    final allTables = await db.query(
      'sqlite_master',
      where: 'type=?',
      whereArgs: ['table'],
      columns: ['name'],
    );

    final records = <(String, List<Map<String, dynamic>>)>[];
    for (final {"name": tableName as String} in allTables) {
      if (tableName.startsWith("sqlite")) continue;

      final rows = await db.query(tableName);
      records.add((tableName, rows));
    }

    if (isDebugMode) {
      printBoxed(allTables);
    }

    return records;
  }

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
    if (isDebugMode) {
      printBoxed(allTables);
    }

    return count;
  }
}
