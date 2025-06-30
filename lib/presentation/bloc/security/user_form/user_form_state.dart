part of 'user_form_bloc.dart';

class UserFormState {
  const UserFormState({
    this.userId,
    this.firstName = '',
    this.lastName = '',
    this.username = '',
    this.accessLevel = '',
    this.oldPassword = '',
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
    this.oldPasswordErrorMessage,
    this.passwordErrorMessage,
    this.confirmPasswordErrorMessage,
  });

  factory UserFormState.fromUser(User user, List<FormQuestion> questions) {
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
      questions: questions.isEmpty
          ? [
              const FormQuestion(question: "", answer: ""),
              const FormQuestion(question: "", answer: ""),
              const FormQuestion(question: "", answer: ""),
            ]
          : questions,
    );
  }
  final String firstName;
  final String lastName;
  final String username;
  final String accessLevel;
  final String oldPassword;
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
  final String? oldPasswordErrorMessage;
  final String? passwordErrorMessage;
  final String? confirmPasswordErrorMessage;

  UserFormState Function({
    String firstName,
    String lastName,
    String username,
    String accessLevel,
    String oldPassword,
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
    String? oldPasswordErrorMessage,
    String? passwordErrorMessage,
    String? confirmPasswordErrorMessage,
  }) get copyWith {
    return ({
      Object? userId = undefined,
      Object? firstName = undefined,
      Object? lastName = undefined,
      Object? username = undefined,
      Object? accessLevel = undefined,
      Object? oldPassword = undefined,
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
      Object? oldPasswordErrorMessage = undefined,
      Object? passwordErrorMessage = undefined,
      Object? confirmPasswordErrorMessage = undefined,
    }) {
      return UserFormState(
        userId: userId.or(this.userId),
        firstName: firstName.or(this.firstName),
        lastName: lastName.or(this.lastName),
        username: username.or(this.username),
        accessLevel: accessLevel.or(this.accessLevel),
        oldPassword: oldPassword.or(this.oldPassword),
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
        oldPasswordErrorMessage: oldPasswordErrorMessage.or(this.oldPasswordErrorMessage),
        passwordErrorMessage: passwordErrorMessage.or(this.passwordErrorMessage),
        confirmPasswordErrorMessage:
            confirmPasswordErrorMessage.or(this.confirmPasswordErrorMessage),
      );
    };
  }

  User mapStateToUser() {
    return User(
      id: userId,
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
