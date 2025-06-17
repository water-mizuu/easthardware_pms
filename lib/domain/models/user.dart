import "dart:convert";
import "dart:typed_data";

import "package:easthardware_pms/domain/enums/enums.dart";
import "package:easthardware_pms/utils/undefined.dart";

class User {
  const User({
    required this.uid,
    this.id,
    required this.firstName,
    required this.lastName,
    required this.username,
    required this.accessLevel,
    required this.passwordHash,
    required this.salt,
    this.archiveStatus,
    required this.loginStatus,
    required this.creationDate,
  });

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as int,
      uid: map['uid'] as String,
      firstName: map['first_name'] as String,
      lastName: map['last_name'] as String,
      username: map['username'] as String,
      accessLevel: AccessLevel.values[map['access_level'] as int],
      passwordHash: base64Decode(map['password_hash'] as String),
      salt: base64Decode(map['salt'] as String),
      creationDate: map['creation_date'] as String,
      archiveStatus: map['archived_status'] as int?,
      loginStatus: map['login_status'] as int,
    );
  }
  final int? id;
  final String uid;
  final String firstName;
  final String lastName;
  final String username;
  final AccessLevel accessLevel;
  final Uint8List salt;
  final Uint8List passwordHash;
  final int? archiveStatus;
  final int loginStatus;
  final String creationDate;

  User Function({
    int? id,
    String? uid,
    String? firstName,
    String? lastName,
    String? username,
    AccessLevel? accessLevel,
    Uint8List? passwordHash,
    Uint8List? salt,
    int? archiveStatus,
    int? loginStatus,
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
      Object? archiveStatus = undefined,
      Object? loginStatus = undefined,
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
        archiveStatus: archiveStatus.or(this.archiveStatus),
        loginStatus: loginStatus.or(this.loginStatus),
        creationDate: creationDate.or(this.creationDate),
      );
    };
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'uid': uid,
      'first_name': firstName,
      'last_name': lastName,
      'username': username,
      'access_level': accessLevel.index,
      'password_hash': base64Encode(passwordHash),
      'salt': base64Encode(salt),
      'archive_status': archiveStatus,
      'login_status': loginStatus,
      'creation_date': creationDate,
    };
  }
}
