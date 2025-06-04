import 'package:easthardware_pms/data/database/database_helper.dart';
import 'package:easthardware_pms/data/repository/authentication_repository.dart';
import 'package:easthardware_pms/domain/models/user.dart';

abstract interface class AuthenticationRepository {
  factory AuthenticationRepository(DatabaseHelper? databaseHelper) {
    return AuthenticationRepositoryImpl(databaseHelper);
  }

  Future<User> logIn({required String username, required String password});
  void logOut({required int userId});
  void dispose();
}
