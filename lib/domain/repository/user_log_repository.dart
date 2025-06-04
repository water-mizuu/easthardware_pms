import 'package:easthardware_pms/data/database/database_helper.dart';
import 'package:easthardware_pms/data/repository/user_log_repository.dart';
import 'package:easthardware_pms/domain/models/user_log.dart';

abstract class UserLogRepository {
  factory UserLogRepository(DatabaseHelper? databaseHelper) = UserLogRepositoryImpl;

  Future<List<UserLog>> getAllUserLogs();
  Future<UserLog?> getUserLogById(int id);
  Future<List<UserLog>> getUserLogByUserId(int id);

  Future<UserLog> insertUserLog(UserLog userLog);
  Future<UserLog> updateUserLog(UserLog userLog);
  Future<void> deleteUserLog(UserLog userLog);
}
