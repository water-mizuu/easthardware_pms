import 'package:easthardware_pms/data/database/database_helper.dart';
import 'package:easthardware_pms/data/repository/authentication_repository.dart';
import 'package:easthardware_pms/data/repository/http_authentication_repository.dart';
import 'package:easthardware_pms/domain/models/user.dart';
import 'package:easthardware_pms/presentation/bloc/server/server_bloc.dart';

enum AuthenticationStatus { unknown, authenticated, unauthenticated }

abstract interface class AuthenticationRepository {
  factory AuthenticationRepository(DatabaseArgs? args, DatabaseHelper? databaseHelper) {
    if (args is ClientDatabaseArgs) {
      return HttpAuthenticationRepositoryImpl(args);
    }
    return AuthenticationRepositoryImpl(databaseHelper);
  }

  Future<User> logIn({required String username, required String password});
  void logOut();
  void dispose();
}
