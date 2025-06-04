import 'package:easthardware_pms/data/database/database_helper.dart';
import 'package:easthardware_pms/data/repository/user_repository.dart';
import 'package:easthardware_pms/domain/models/user.dart';

abstract class UserRepository {
  factory UserRepository(DatabaseHelper? databaseHelper) = UserRepositoryImpl;

  Future<List<User>> getAllUsers();
  Future<User?> getUserById(int id);
  Future<User?> getUserByUsername(String username);

  Future<User> insertUser(User user);
  Future<User> updateUser(User user);
  Future<void> deleteUser(User user);
  Future<void> updatePassword(String username, String newPassword);

  Future<void> setUserAsActive(int userId);
  Future<void> setUserAsInactive(int userId);
}
