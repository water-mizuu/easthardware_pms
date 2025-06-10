import 'package:easthardware_pms/data/database/dao/units_dao.dart';
import 'package:easthardware_pms/data/database/database_helper.dart';
import 'package:easthardware_pms/domain/errors/exceptions.dart';
import 'package:easthardware_pms/domain/models/unit.dart';
import 'package:easthardware_pms/domain/repository/unit_repository.dart';

class UnitRepositoryImpl implements UnitRepository {
  @Deprecated("Do not use this constructor directly.")
  UnitRepositoryImpl(DatabaseHelper? databaseHelper) : _unitsDao = UnitsDao(databaseHelper);

  final UnitsDao _unitsDao;

  @override
  Future<void> deleteUnit(int id) {
    try {
      return _unitsDao.deleteUnit(id);
    } catch (e) {
      throw DatabaseException("Failed to delete unit: $e");
    }
  }

  @override
  Future<List<Unit>> getAllUnits() {
    try {
      return _unitsDao.getAllUnits();
    } catch (e) {
      throw DatabaseException("Failed to fetch units: $e");
    }
  }

  @override
  Future<Unit?> getUnitById(int id) {
    try {
      return _unitsDao.getUnitById(id);
    } catch (e) {
      throw DatabaseException("Failed to fetch unit: $e");
    }
  }

  @override
  Future<Unit> insertUnit(Unit unit) {
    // Validate the unit before inserting
    _validateUnit(unit);
    try {
      return _unitsDao.insertUnit(unit);
    } catch (e) {
      throw DatabaseException("Failed to insert unit: $e");
    }
  }

  @override
  Future<Unit> updateUnit(Unit unit) {
    // Validate the unit before updating
    _validateUnit(unit);
    try {
      return _unitsDao.updateUnit(unit);
    } catch (e) {
      throw DatabaseException("Failed to update unit: $e");
    }
  }

  void _validateUnit(Unit unit) {
    if (unit.name.isEmpty) {
      throw ArgumentException('Unit name cannot be empty');
    }
    if (unit.mainQuantity * unit.unitQuantity <= 0) {
      throw ArgumentException('Conversion factor must be greater than zero');
    }
  }

  @override
  Future<List<Unit>> getAllUnitsOfProductId(int productId) {
    try {
      return _unitsDao.getAllUnitsOfProduct(productId);
    } catch (e) {
      throw DatabaseException("Failed to fetch units of product: $e");
    }
  }
}
