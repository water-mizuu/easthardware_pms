import 'package:easthardware_pms/data/database/dao/dao_base.dart';
import 'package:easthardware_pms/data/database/database_helper.dart';
import 'package:easthardware_pms/data/database/tables/users_table.dart';
import 'package:easthardware_pms/domain/models/user.dart';

abstract interface class UsersDao {
  factory UsersDao(DatabaseHelper? databaseHelper) {
    return UsersDaoImpl._(databaseHelper);
  }
  Future<List<User>> getAllUsers();
  Future<User?> getUserById(int id);
  Future<User?> getUserByUid(String uid);
  Future<User?> getUserByUsername(String username);

  Future<User> insertUser(User user);
  Future<User> updateUser(User user);
  Future<void> deleteUser(User user);
  Future<void> updatePassword(
      String username, String newPasswordHash, String salt);
}

final class UsersDaoImpl extends DaoBase implements UsersDao {
  const UsersDaoImpl._(super.databaseHelper);

  @override
  Future<List<User>> getAllUsers() async {
    final database = databaseHelper.database;
    final res = await database.query(UsersTable.USERS_TABLE_NAME);

    final users = res.map(User.fromMap).toList();

    return users;
  }

  @override
  Future<User?> getUserById(int id) async {
    final database = databaseHelper.database;
    final res = await database.query(
      UsersTable.USERS_TABLE_NAME,
      where: "${UsersTable.USERS_ID} = ?",
      whereArgs: [id],
    );

    final user = res.isNotEmpty ? User.fromMap(res.first) : null;

    return user;
  }

  @override
  Future<User?> getUserByUsername(String username) async {
    final database = databaseHelper.database;
    final res = await database.query(
      UsersTable.USERS_TABLE_NAME,
      where: "${UsersTable.USERS_USERNAME} = ?",
      whereArgs: [username],
    );

    final user = res.isNotEmpty ? User.fromMap(res.first) : null;

    return user;
  }

  @override
  Future<User> insertUser(User user) async {
    final database = databaseHelper.database;
    final id = await database.insert(UsersTable.USERS_TABLE_NAME, user.toMap());
    return user.copyWith(id: id);
  }

  @override
  Future<User> updateUser(User user) async {
    final database = databaseHelper.database;
    await database.update(
      UsersTable.USERS_TABLE_NAME,
      user.toMap(),
      where: "${UsersTable.USERS_ID} = ?",
      whereArgs: [user.id],
    );
    return user;
  }

  @override
  Future<void> deleteUser(User user) async {
    final database = databaseHelper.database;
    await database.delete(
      UsersTable.USERS_TABLE_NAME,
      where: "${UsersTable.USERS_ID} = ?",
      whereArgs: [user.id],
    );
  }

  @override
  Future<User?> getUserByUid(String uid) async {
    final database = databaseHelper.database;
    final res = await database.query(
      UsersTable.USERS_TABLE_NAME,
      where: "${UsersTable.USERS_UID} = ?",
      whereArgs: [uid],
    );

    final user = res.isNotEmpty ? User.fromMap(res.first) : null;

    return user;
  }

  @override
  Future<void> updatePassword(
      String username, String newPasswordHash, String salt) async {
    final database = databaseHelper.database;

    await database.update(
      UsersTable.USERS_TABLE_NAME,
      {
        UsersTable.USERS_PASSWORD_HASH: newPasswordHash,
        UsersTable.USERS_SALT: salt,
      },
      where: "${UsersTable.USERS_USERNAME} = ?",
      whereArgs: [username],
    );
  }
}
