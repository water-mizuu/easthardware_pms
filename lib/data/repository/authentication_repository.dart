import 'dart:async';
import 'dart:typed_data';

import 'package:easthardware_pms/data/database/database_helper.dart';
import 'package:easthardware_pms/data/repository/user_repository.dart';
import 'package:easthardware_pms/domain/errors/exceptions.dart';
import 'package:easthardware_pms/domain/models/user.dart';
import 'package:easthardware_pms/domain/repository/authentication_repository.dart';
import 'package:easthardware_pms/domain/repository/user_repository.dart';
import 'package:easthardware_pms/domain/services/cryptography_service.dart';

/// authentication_repository.dart
/// This dart file includes the implementation of the authentication abstract class in the domain
///
/// The AuthenticationRepository implementation shall be responsible for defining authentication domain functions (e.g. Logging in, Logging out) that have additional logic aside from interacting with the database.
///

class AuthenticationRepositoryImpl implements AuthenticationRepository {
  AuthenticationRepositoryImpl(DatabaseHelper? databaseHelper)
      : _userRepository = UserRepositoryImpl(databaseHelper);

  final UserRepository _userRepository;

  /// Attempts to log in a user with inputted credentials
  /// @param [username] The string username of the user
  /// @param [password] The string password of the user
  /// @returns user if the login was successful to pass throughout the app
  /// @throws [AuthenticationException] if the username or password is invalid
  ///
  @override
  Future<User> logIn({required String username, required String password}) async {
    // _validateInput(username, password);
    // Check if the user exists in the database
    final User? user = await _userRepository.getUserByUsername(username);

    if (user == null) {
      throw AuthenticationException('Invalid username or password');
    }
    // Hash the input password
    final Uint8List hashedPassword = CryptographyService.generateHash(password, user.salt);
    // Compare the hashed password with the stored password
    if (user.passwordHash.toString() != hashedPassword.toString()) {
      throw AuthenticationException('Invalid username or password');
    }

    return user;
  }

  @override
  void logOut() {}

  @override
  void dispose() {}

  // void _validateInput(String username, String password) {
  //   if (username.isEmpty || password.isEmpty) {
  //     throw AuthenticationException('Username and password cannot be empty');
  //   }
  //   if (username.length < 3 || password.length < 6) {
  //     throw AuthenticationException(
  //         'Username must be at least 3 characters and password must be at least 6 characters');
  //   }
  //   if (username.length > 20 || password.length > 20) {
  //     throw AuthenticationException(
  //         'Username must be at most 20 characters and password must be at most 20 characters');
  //   }
  // }
}
