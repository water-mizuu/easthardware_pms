import 'package:easthardware_pms/data/database/database_helper.dart';
import 'package:easthardware_pms/data/repository/unit_repository.dart';
import 'package:easthardware_pms/domain/models/unit.dart';

abstract class UnitRepository {
  // ignore: deprecated_member_use_from_same_package
  factory UnitRepository(DatabaseHelper? databaseHelper) = UnitRepositoryImpl;

  Future<List<Unit>> getAllUnits();
  Future<Unit?> getUnitById(int id);
  Future<List<Unit>> getAllUnitsOfProductId(int productId);

  Future<Unit> insertUnit(Unit unit);
  Future<Unit> updateUnit(Unit unit);
  Future<void> deleteUnit(int id);
}
