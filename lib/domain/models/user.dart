import "dart:typed_data";

import "package:easthardware_pms/domain/enums/enums.dart";

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

  User copyWith({
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
  }) {
    return User(
      id: id ?? this.id,
      uid: uid ?? this.uid,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      username: username ?? this.username,
      accessLevel: accessLevel ?? this.accessLevel,
      passwordHash: passwordHash ?? this.passwordHash,
      salt: salt ?? this.salt,
      status: status ?? this.status,
      creationDate: creationDate ?? this.creationDate,
    );
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
