import 'package:easthardware_pms/data/database/dao/users_dao.dart';
import 'package:easthardware_pms/data/database/database_helper.dart';
import 'package:easthardware_pms/domain/errors/exceptions.dart';
import 'package:easthardware_pms/domain/models/user.dart';
import 'package:easthardware_pms/domain/repository/user_repository.dart';
import 'package:easthardware_pms/domain/services/cryptography_service.dart';

class UserRepositoryImpl implements UserRepository {
  UserRepositoryImpl(DatabaseHelper? databaseHelper) //
      : _usersDao = UsersDao(databaseHelper);

  final UsersDao _usersDao;

  @override
  Future<User> insertUser(User user) {
    _validateUser(user);
    try {
      return _usersDao.insertUser(user);
    } catch (e) {
      throw DatabaseException('Failed to insert user: $e');
    }
  }

  @override
  Future<void> deleteUser(User user) {
    if (user.id == null || user.id! < 0) {
      throw ArgumentException('Invalid user ID');
    }
    try {
      return _usersDao.deleteUser(user);
    } catch (e) {
      throw DatabaseException('Failed to delete user: $e');
    }
  }

  @override
  Future<User?> getUserById(int id) {
    if (id < 0) {
      throw ArgumentException('Invalid user ID $id');
    }
    try {
      return _usersDao.getUserById(id);
    } catch (e) {
      throw DatabaseException('Failed to fetch user by ID: $e');
    }
  }

  @override
  Future<User?> getUserByUsername(String username) {
    if (username.isEmpty) {
      throw ValidationException('Username cannot be empty');
    }
    try {
      return _usersDao.getUserByUsername(username);
    } catch (e) {
      throw DatabaseException('Failed to fetch user by username: $e');
    }
  }

  @override
  Future<List<User>> getAllUsers() {
    try {
      return _usersDao.getAllUsers();
    } catch (e) {
      throw DatabaseException('Failed to fetch all users: $e');
    }
  }

  @override
  Future<User> updateUser(User user) {
    _validateUser(user);
    try {
      return _usersDao.updateUser(user);
    } catch (e) {
      throw DatabaseException(e.toString());
    }
  }

  void _validateUser(User user) {
    if (user.username.trim().isEmpty) {
      throw ValidationException('Username cannot be empty');
    }
    if (user.passwordHash.isEmpty) {
      throw ValidationException('Password cannot be empty');
    }
    if (user.firstName.trim().isEmpty) {
      throw ValidationException('First name cannot be empty');
    }
    if (user.lastName.trim().isEmpty) {
      throw ValidationException('Last name cannot be empty');
    }
  }

  @override
  Future<void> updatePassword(String username, String newPassword) async {
    if (username.isEmpty) {
      throw ValidationException('Username cannot be empty');
    }

    try {
      final user = await _usersDao.getUserByUsername(username);
      if (user == null) {
        throw ValidationException('User not found');
      }

      final newSalt = CryptographyService.generateSalt();
      final newHash = CryptographyService.generateHash(newPassword, newSalt);

      await _usersDao.updatePassword(
        username,
        newHash,
        newSalt,
      );
    } catch (e) {
      throw DatabaseException('Failed to update password: $e');
    }
  }

  @override
  Future<void> setUserAsActive(int userId) async {
    if (userId < 0) {
      throw ArgumentException('Invalid user ID');
    }
    try {
      await _usersDao.setUserAsActive(userId);
    } catch (e) {
      throw DatabaseException('Failed to set user as active: $e');
    }
  }

  @override
  Future<void> setUserAsInactive(int userId) async {
    if (userId < 0) {
      throw ArgumentException('Invalid user ID');
    }
    try {
      await _usersDao.setUserAsInactive(userId);
    } catch (e) {
      throw DatabaseException('Failed to set user as inactive: $e');
    }
  }
}
