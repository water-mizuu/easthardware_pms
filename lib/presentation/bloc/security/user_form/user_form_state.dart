part of 'user_form_bloc.dart';

class UserFormState extends Equatable {
  const UserFormState({
    this.userId,
    this.firstName = '',
    this.lastName = '',
    this.username = '',
    this.accessLevel = '',
    this.password = '',
    this.confirmPassword = '',
    this.questions = const [
      FormQuestion(question: "", answer: ""),
      FormQuestion(question: "", answer: ""),
      FormQuestion(question: "", answer: ""),
    ],
    this.status = FormStatus.initial,
    this.creationDate,
    this.archivedStatus,
    this.uid,
    this.salt,
    this.passwordHash,
    this.accessLevelErrorMessage,
  });

  factory UserFormState.fromUser(User user) {
    return UserFormState(
      userId: user.id,
      creationDate: user.creationDate,
      firstName: user.firstName,
      lastName: user.lastName,
      username: user.username,
      accessLevel: user.accessLevel.name,
      passwordHash: user.passwordHash,
      salt: user.salt,
      archivedStatus: user.archiveStatus,
      uid: user.uid,
    );
  }
  final String firstName;
  final String lastName;
  final String username;
  final String accessLevel;
  final String password;
  final String confirmPassword;
  final List<FormQuestion> questions;
  final FormStatus status;

  // Hidden attributes
  final int? userId;
  final String? creationDate;
  final String? uid;
  final Uint8List? salt;
  final Uint8List? passwordHash;
  final int? archivedStatus;

  // Hidden attributes for the UI
  final String? accessLevelErrorMessage;

  @override
  List<Object> get props => [
        firstName,
        lastName,
        username,
        accessLevel,
        password,
        questions,
        status,
        creationDate ?? '',
        archivedStatus ?? 0,
        uid ?? '',
        salt ?? Uint8List(0),
        passwordHash ?? Uint8List(0),
        accessLevelErrorMessage ?? '',
        userId ?? 0,
      ];

  UserFormState Function({
    String firstName,
    String lastName,
    String username,
    String accessLevel,
    String password,
    String confirmPassword,
    List<FormQuestion> questions,
    FormStatus status,
    int? userId,
    String? creationDate,
    String? uid,
    Uint8List? salt,
    Uint8List? passwordHash,
    int? archivedStatus,
    String? accessLevelErrorMessage,
  }) get copyWith {
    return ({
      Object? userId = undefined,
      Object? firstName = undefined,
      Object? lastName = undefined,
      Object? username = undefined,
      Object? accessLevel = undefined,
      Object? password = undefined,
      Object? confirmPassword = undefined,
      Object? questions = undefined,
      Object? status = undefined,
      Object? creationDate = undefined,
      Object? archivedStatus = undefined,
      Object? uid = undefined,
      Object? salt = undefined,
      Object? passwordHash = undefined,
      Object? accessLevelErrorMessage = undefined,
    }) {
      return UserFormState(
        userId: userId.or(this.userId),
        firstName: firstName.or(this.firstName),
        lastName: lastName.or(this.lastName),
        username: username.or(this.username),
        accessLevel: accessLevel.or(this.accessLevel),
        password: password.or(this.password),
        confirmPassword: confirmPassword.or(this.confirmPassword),
        questions: questions.or(this.questions),
        status: status.or(this.status),
        creationDate: creationDate.or(this.creationDate),
        archivedStatus: archivedStatus.or(this.archivedStatus),
        uid: uid.or(this.uid),
        salt: salt.or(this.salt),
        passwordHash: passwordHash.or(this.passwordHash),
        accessLevelErrorMessage: accessLevelErrorMessage.or(this.accessLevelErrorMessage),
      );
    };
  }

  User mapStateToUser() {
    return User(
      uid: uid!,
      firstName: firstName,
      lastName: lastName,
      username: username,
      accessLevel: AccessLevel.values.firstWhere((element) => element.name == accessLevel),
      passwordHash: passwordHash!,
      salt: salt!,
      archiveStatus: archivedStatus!,
      loginStatus: 0, // Default login status
      creationDate: creationDate!,
    );
  }
}
