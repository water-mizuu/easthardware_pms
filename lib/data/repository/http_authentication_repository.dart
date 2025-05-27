import 'package:easthardware_pms/domain/models/user.dart';
import 'package:easthardware_pms/domain/repository/authentication_repository.dart'
    show AuthenticationRepository;
import 'package:easthardware_pms/presentation/bloc/server/server_bloc.dart' show ClientDatabaseArgs;

class HttpAuthenticationRepositoryImpl implements AuthenticationRepository {
  const HttpAuthenticationRepositoryImpl(this._clientDatabaseArgs);

  final ClientDatabaseArgs _clientDatabaseArgs;

  @override
  void dispose() {
    // TODO: implement dispose
  }

  @override
  Future<User> logIn({required String username, required String password}) async {
    final target = "${_clientDatabaseArgs.parentIp}:${_clientDatabaseArgs.port}";
    final uri = Uri.parse("http://$target/auth");

    // TODO: implement logIn
    throw UnimplementedError();
  }

  @override
  void logOut() {
    // TODO: implement logOut
  }
}
