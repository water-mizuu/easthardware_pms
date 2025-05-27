import 'package:easthardware_pms/backend/enum/database_mode.dart';
import 'package:easthardware_pms/data/database/database_helper.dart';
import 'package:easthardware_pms/data/repository/authentication_repository.dart';
import 'package:easthardware_pms/domain/models/user.dart';

enum AuthenticationStatus { unknown, authenticated, unauthenticated }

abstract interface class AuthenticationRepository {
  factory AuthenticationRepository(DatabaseMode? mode, DatabaseHelper? databaseHelper) {
    return AuthenticationRepositoryImpl(databaseHelper);
  }

  Future<User> logIn({required String username, required String password});
  void logOut();
  void dispose();
}
