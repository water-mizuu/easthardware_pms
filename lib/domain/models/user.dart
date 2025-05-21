import "dart:typed_data";

import "package:easthardware_pms/domain/enums/enums.dart";
import "package:easthardware_pms/utils/undefined.dart";

class User {
  final int? id;
  final String uid;
  final String firstName;
  final String lastName;
  final String username;
  final AccessLevel accessLevel;
  final Uint8List salt;
  final Uint8List passwordHash;
  final int status;
  final String creationDate;

  User({
    required this.uid,
    this.id,
    required this.firstName,
    required this.lastName,
    required this.username,
    required this.accessLevel,
    required this.passwordHash,
    required this.salt,
    required this.status,
    required this.creationDate,
  });

  User Function({
    int? id,
    String? uid,
    String? firstName,
    String? lastName,
    String? username,
    AccessLevel? accessLevel,
    Uint8List? passwordHash,
    Uint8List? salt,
    int? status,
    String? creationDate,
  }) get copyWith {
    return ({
      Object? id = undefined,
      Object? uid = undefined,
      Object? firstName = undefined,
      Object? lastName = undefined,
      Object? username = undefined,
      Object? accessLevel = undefined,
      Object? passwordHash = undefined,
      Object? salt = undefined,
      Object? status = undefined,
      Object? creationDate = undefined,
    }) {
      return User(
        id: id.or(this.id),
        uid: uid.or(this.uid),
        firstName: firstName.or(this.firstName),
        lastName: lastName.or(this.lastName),
        username: username.or(this.username),
        accessLevel: accessLevel.or(this.accessLevel),
        passwordHash: passwordHash.or(this.passwordHash),
        salt: salt.or(this.salt),
        status: status.or(this.status),
        creationDate: creationDate.or(this.creationDate),
      );
    };
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'uid': uid,
      'first_name': firstName,
      'last_name': lastName,
      'username': username,
      'access_level': accessLevel.index,
      'password_hash': passwordHash,
      'salt': salt,
      'status': status,
      'creation_date': creationDate,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as int,
      uid: map['uid'] as String,
      firstName: map['first_name'] as String,
      lastName: map['last_name'] as String,
      username: map['username'] as String,
      accessLevel: AccessLevel.values[map['access_level'] as int],
      passwordHash: Uint8List.fromList((map['password_hash'] as List<dynamic>).cast<int>()),
      salt: Uint8List.fromList((map['salt'] as List<dynamic>).cast<int>()),
      creationDate: map['creation_date'] as String,
      status: map['status'] as int,
    );
  }
}
