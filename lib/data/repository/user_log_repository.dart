import 'package:easthardware_pms/data/database/dao/user_logs_dao.dart';
import 'package:easthardware_pms/data/database/database_helper.dart';
import 'package:easthardware_pms/domain/errors/exceptions.dart';
import 'package:easthardware_pms/domain/models/user_log.dart';
import 'package:easthardware_pms/domain/repository/user_log_repository.dart';

class UserLogRepositoryImpl implements UserLogRepository {
  UserLogRepositoryImpl(DatabaseHelper? databaseHelper)
      : _userLogsDao = UserLogsDao(databaseHelper);

  final UserLogsDao _userLogsDao;

  @override
  Future<UserLog> insertUserLog(UserLog userLog) async {
    try {
      return await _userLogsDao.insertUserLog(userLog);
    } catch (e) {
      throw DatabaseException("Failed to insert user log: $e");
    }
  }

  @override
  Future<void> deleteUserLog(UserLog userLog) async {
    try {
      await _userLogsDao.deleteUserLog(userLog);
    } catch (e) {
      throw DatabaseException("Failed to delete user log: $e");
    }
  }

  @override
  Future<List<UserLog>> getAllUserLogs() async {
    try {
      return await _userLogsDao.getAllUserLogs();
    } catch (e) {
      throw DatabaseException("Failed to fetch user logs: $e");
    }
  }

  @override
  Future<UserLog?> getUserLogById(int id) async {
    try {
      return await _userLogsDao.getUserLogById(id);
    } catch (e) {
      throw DatabaseException("Failed to fetch user log: $e");
    }
  }

  @override
  Future<List<UserLog>> getUserLogByUserId(int id) async {
    try {
      return await _userLogsDao.getUserLogsByUserId(id);
    } catch (e) {
      throw DatabaseException("Failed to fetch user log: $e");
    }
  }

  @override
  Future<UserLog> updateUserLog(UserLog userLog) async {
    try {
      return await _userLogsDao.updateUserLog(userLog);
    } catch (e) {
      throw DatabaseException("Failed to update user log: $e");
    }
  }
}
