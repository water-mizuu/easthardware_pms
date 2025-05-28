// import 'dart:convert';

// import 'package:easthardware_pms/backend/secure_http.dart';
// import 'package:easthardware_pms/domain/models/user.dart';
// import 'package:easthardware_pms/domain/repository/authentication_repository.dart'
//     show AuthenticationRepository;
// import 'package:easthardware_pms/presentation/bloc/server/server_bloc.dart' show ClientDatabaseArgs;
// import 'package:easthardware_pms/utils/boxed.dart';
// import 'package:flutter/foundation.dart';

// class HttpAuthenticationRepositoryImpl implements AuthenticationRepository {
//   const HttpAuthenticationRepositoryImpl(this._clientDatabaseArgs);

//   final ClientDatabaseArgs _clientDatabaseArgs;

//   @override
//   void dispose() {
//     // TODO: implement dispose
//   }

//   @override
//   Future<User> logIn({required String username, required String password}) async {
//     final target = "${_clientDatabaseArgs.parentIp}:${_clientDatabaseArgs.port}";
//     final payload = {
//       "username": username,
//       "password": password,
//     };

//     final encoded = jsonEncode(payload);
//     final uri = Uri.parse("http://$target/auth");
//     final response = await SecureHttp.post(uri, body: encoded);
//     if (response.statusCode != 200) {
//       throw Exception('Failed to log in: ${response.body}');
//     }

//     if (kDebugMode) {
//       printBoxed(response.body, "auth-response");
//     }

//     final decodedResponse = jsonDecode(response.body);
//     if (decodedResponse is! Map<String, dynamic>) {
//       throw Exception('Invalid response format: $decodedResponse');
//     }
//     final user = User.fromMap(decodedResponse);

//     return user;
//   }

//   @override
//   void logOut() {
//     // TODO: implement logOut
//   }
// }
