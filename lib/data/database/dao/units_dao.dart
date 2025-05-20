import 'package:easthardware_pms/data/database/dao/dao_base.dart';
import 'package:easthardware_pms/data/database/database_helper.dart';
import 'package:easthardware_pms/data/database/tables/units_table.dart';
import 'package:easthardware_pms/domain/models/unit.dart';

abstract interface class UnitsDao {
  factory UnitsDao(DatabaseHelper? databaseHelper) {
    return UnitsDaoImpl._(databaseHelper);
  }
  Future<List<Unit>> getAllUnits();
  Future<List<Unit>> getAllUnitsOfProduct(int id);
  Future<Unit?> getUnitById(int id);

  Future<Unit> insertUnit(Unit unit);
  Future<Unit> updateUnit(Unit unit);
  Future<void> deleteUnit(int id);
}

final class UnitsDaoImpl extends DaoBase implements UnitsDao {
  const UnitsDaoImpl._(super.databaseHelper);

  @override
  Future<void> deleteUnit(int id) async {
    final database = databaseHelper.database;
    await database.delete(
      UnitsTable.UNITS_TABLE_NAME,
      where: "${UnitsTable.UNITS_TABLE_NAME} = ?",
      whereArgs: [id],
    );
  }

  @override
  Future<List<Unit>> getAllUnits() async {
    final database = databaseHelper.database;
    var res = await database.query(UnitsTable.UNITS_TABLE_NAME);

    List<Unit>? units = res.isNotEmpty ? res.map(Unit.fromMap).toList() : [];
    return units;
  }

  @override
  Future<Unit?> getUnitById(int id) async {
    final database = databaseHelper.database;
    var res = await database.query(
      UnitsTable.UNITS_TABLE_NAME,
      where: "${UnitsTable.UNITS_ID} = ?",
      whereArgs: [id],
    );

    Unit? unit = res.isNotEmpty ? Unit.fromMap(res.first) : null;
    return unit;
  }

  @override
  Future<Unit> insertUnit(Unit unit) async {
    final database = databaseHelper.database;
    final id = await database.insert(UnitsTable.UNITS_TABLE_NAME, unit.toMap());
    return unit.copyWith(id: id);
  }

  @override
  Future<Unit> updateUnit(Unit unit) async {
    final database = databaseHelper.database;
    await database.update(
      UnitsTable.UNITS_TABLE_NAME,
      unit.toMap(),
      where: "${UnitsTable.UNITS_ID} = ?",
      whereArgs: [unit.id],
    );
    return unit;
  }

  @override
  Future<List<Unit>> getAllUnitsOfProduct(int id) async {
    final database = databaseHelper.database;
    var res = await database.query(
      UnitsTable.UNITS_TABLE_NAME,
      where: "${UnitsTable.UNITS_PRODUCT_ID} = ?",
      whereArgs: [id],
    );

    List<Unit>? units = res.isNotEmpty ? res.map(Unit.fromMap).toList() : [];
    return units;
  }
}
