import 'dart:typed_data';

import 'package:bloc/bloc.dart';
import 'package:easthardware_pms/domain/enums/enums.dart';
import 'package:easthardware_pms/domain/models/user.dart';
import 'package:easthardware_pms/domain/services/cryptography_service.dart';
import 'package:easthardware_pms/presentation/models/form_question.dart';
import 'package:easthardware_pms/utils/boxed.dart';
import 'package:easthardware_pms/utils/undefined.dart';
import 'package:equatable/equatable.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

part 'user_form_event.dart';
part 'user_form_state.dart';

class UserFormBloc extends Bloc<UserFormEvent, UserFormState> {
  UserFormBloc()
      : formKey = GlobalKey<FormState>(),
        super(const UserFormState()) {
    on<UserIdChangedEvent>(_onUserIdChanged);
    on<FirstNameFieldChangedEvent>(_onFirstNameChanged);
    on<LastNameFieldChangedEvent>(_onLastNameChanged);
    on<UsernameFieldChangedEvent>(_onUsernameChanged);
    on<PasswordFieldChangedEvent>(_onPasswordChanged);
    on<OldPasswordFieldChangedEvent>(_onOldPasswordChanged);
    on<ConfirmPasswordFieldChangedEvent>(_onConfirmPasswordChanged);
    on<AccessLevelFieldChangedEvent>(_onAccessLevelChanged);
    on<QuestionFieldChangedEvent>(_onQuestionChanged);
    on<AnswerFieldChangedEvent>(_onAnswerChanged);
    on<FormButtonPressedEvent>(_onSaveUserRequested);
    on<FormResetEvent>(_onFormReset);
    on<SecurityQuestionsUpdatedEvent>(_onSecurityQuestionsUpdated);
    on<UpdateUserRequestEvent>(_onUpdateUserRequested);
    on<UIDChangedEvent>((event, emit) {
      emit(state.copyWith(uid: event.uid));
    });
    on<LoadSaltAndHashEvent>(_onLoadSaltAndHash);
  }
  final GlobalKey<FormState> formKey;

  Future<void> _onUserIdChanged(UserIdChangedEvent event, Emitter emit) async {
    try {
      emit(state.copyWith(userId: event.userId));
    } catch (e) {
      emit(state.copyWith(status: FormStatus.error));
    }
  }

  Future<void> _onFirstNameChanged(FirstNameFieldChangedEvent event, Emitter emit) async {
    try {
      emit(state.copyWith(firstName: event.firstName));
    } catch (e) {
      emit(state.copyWith(status: FormStatus.error));
    }
  }

  Future<void> _onLastNameChanged(LastNameFieldChangedEvent event, Emitter emit) async {
    try {
      emit(state.copyWith(lastName: event.lastName));
    } catch (e) {
      emit(state.copyWith(status: FormStatus.error));
    }
  }

  Future<void> _onUsernameChanged(UsernameFieldChangedEvent event, Emitter emit) async {
    try {
      emit(state.copyWith(username: event.username));
    } catch (e) {
      emit(state.copyWith(status: FormStatus.error));
    }
  }

  Future<void> _onPasswordChanged(PasswordFieldChangedEvent event, Emitter emit) async {
    try {
      emit(state.copyWith(password: event.password));
    } catch (e) {
      emit(state.copyWith(status: FormStatus.error));
    }
  }

  Future<void> _onOldPasswordChanged(OldPasswordFieldChangedEvent event, Emitter emit) async {
    try {
      emit(state.copyWith(oldPassword: event.oldPassword));
    } catch (e) {
      emit(state.copyWith(status: FormStatus.error));
    }
  }

  Future<void> _onConfirmPasswordChanged(
      ConfirmPasswordFieldChangedEvent event, Emitter emit) async {
    try {
      emit(state.copyWith(confirmPassword: event.confirmPassword));
    } catch (e) {
      emit(state.copyWith(status: FormStatus.error));
    }
  }

  Future<void> _onAccessLevelChanged(AccessLevelFieldChangedEvent event, Emitter emit) async {
    try {
      emit(state.copyWith(accessLevel: event.accessLevel));
    } catch (e) {
      emit(state.copyWith(status: FormStatus.error));
    }
  }

  Future<void> _onQuestionChanged(QuestionFieldChangedEvent event, Emitter emit) async {
    try {
      final question = event.question;
      final index = event.index;
      final updatedQuestions = List<FormQuestion>.from(state.questions);

      updatedQuestions[index] = updatedQuestions[index].copyWith(question: question);
      emit(state.copyWith(questions: updatedQuestions));
    } catch (e) {
      emit(state.copyWith(status: FormStatus.error));
    }
  }

  Future<void> _onAnswerChanged(AnswerFieldChangedEvent event, Emitter emit) async {
    try {
      final answer = event.answer;
      final index = event.index;
      final updatedQuestions = List<FormQuestion>.from(state.questions);

      updatedQuestions[index] = updatedQuestions[index].copyWith(answer: answer);
      emit(state.copyWith(questions: updatedQuestions));
    } catch (e) {
      emit(state.copyWith(status: FormStatus.error));
    }
  }

  Future<void> _onSaveUserRequested(FormButtonPressedEvent event, Emitter emit) async {
    try {
      // First set the state to validating to show validation is in progress
      emit(state.copyWith(status: FormStatus.validating));

      // 1. Check if access level is selected
      if (state.accessLevel.trim().isEmpty) {
        // For displaying error message
        emit(state.copyWith(
          accessLevelErrorMessage: 'Please select an access level',
          status: FormStatus.error,
        ));
        return;
      }
      if (formKey.currentState case final FormState formState when formState.validate()) {
        final uid = const Uuid().v4();
        final creationDate = DateTime.now().toIso8601String();
        final salt = CryptographyService.generateSalt();
        final passwordHash = CryptographyService.generateHash(state.password, salt);

        // All validations passed, submit the form
        emit(
          state.copyWith(
            uid: uid,
            creationDate: creationDate,
            salt: salt,
            archivedStatus: 0,
            passwordHash: passwordHash,
            accessLevelErrorMessage: null,
            status: FormStatus.submitting,
          ),
        );
      } else {
        // Form validation failed
        emit(state.copyWith(status: FormStatus.error));
      }
    } catch (e) {
      emit(state.copyWith(status: FormStatus.error));
    }
  }

  Future<void> _onFormReset(FormResetEvent event, Emitter emit) async {
    try {
      emit(const UserFormState());
    } catch (e) {
      emit(state.copyWith(status: FormStatus.error));
    }
  }

  Future<void> _onSecurityQuestionsUpdated(
      SecurityQuestionsUpdatedEvent event, Emitter emit) async {
    try {
      emit(state.copyWith(questions: event.questions));
    } catch (e) {
      emit(state.copyWith(status: FormStatus.error));
    }
  }

  Future<void> _onUpdateUserRequested(
      UpdateUserRequestEvent event, Emitter<UserFormState> emit) async {
    // First set the state to validating to show validation is in progress
    emit(state.copyWith(status: FormStatus.validating));

    // Validation checks

    // 1. Check if access level is selected
    if (state.accessLevel.trim().isEmpty) {
      emit(state.copyWith(
        accessLevelErrorMessage: 'Please select an access level',
        status: FormStatus.error,
      ));
      return;
    } // 2. Check if all provided security questions have answers
    var hasEmptyQuestion = false;
    for (final question in state.questions) {
      // If a question is provided, it must have an answer
      if (question.question.isNotEmpty && question.answer.isEmpty) {
        hasEmptyQuestion = true;
        break;
      }
    }

    if (hasEmptyQuestion) {
      emit(state.copyWith(
        accessLevelErrorMessage: 'All security questions must have answers',
        status: FormStatus.error,
      ));
      return;
    }

    // 3. Use the form key to validate the form (this will validate all the form fields)
    if (formKey.currentState case final FormState formState when formState.validate()) {
      // Password validation logic
      final hasOldPassword = state.oldPassword.isNotEmpty;
      final hasNewPassword = state.password.isNotEmpty;
      final hasConfirmPassword = state.confirmPassword.isNotEmpty;

      printBoxed(
          'hasOldPassword: $hasOldPassword, \n hasNewPassword: $hasNewPassword, \n hasConfirmPassword: $hasConfirmPassword');

      // Check if new password fields match when provided
      if (hasNewPassword || hasConfirmPassword || hasOldPassword) {
        // If any password field is filled, all should be filled
        if (!hasOldPassword) {
          emit(state.copyWith(
            oldPasswordErrorMessage: 'Please fill in all password fields to change password',
            status: FormStatus.error,
          ));
        }
        if (!hasNewPassword) {
          emit(state.copyWith(
            passwordErrorMessage: 'Please fill in all password fields to change password',
            status: FormStatus.error,
          ));
        }
        if (!hasConfirmPassword) {
          emit(state.copyWith(
            confirmPasswordErrorMessage: 'Please fill in all password fields to change password',
            status: FormStatus.error,
          ));
          return;
        }

        // Verify new password matches confirm password
        if (state.password != state.confirmPassword) {
          emit(state.copyWith(
            confirmPasswordErrorMessage: 'New password and confirmation do not match',
            status: FormStatus.error,
          ));
          return;
        }

        // Verify old password with stored hash
        if (state.salt != null && state.passwordHash != null) {
          final oldPasswordHash = CryptographyService.generateHash(state.oldPassword, state.salt!);
          if (!listEquals(oldPasswordHash, state.passwordHash)) {
            emit(state.copyWith(
              oldPasswordErrorMessage: 'Current password is incorrect',
              status: FormStatus.error,
            ));
            return;
          }
        }
      }

      // Generate password hash only if a new password is provided
      Uint8List? newSalt;
      Uint8List? newPasswordHash;

      if (hasNewPassword) {
        newSalt = CryptographyService.generateSalt();
        newPasswordHash = CryptographyService.generateHash(state.password, newSalt);
      }

      // All validations passed, submit the form
      emit(
        state.copyWith(
          archivedStatus: 0,
          salt: newSalt,
          passwordHash: hasNewPassword
              ? newPasswordHash
              : CryptographyService.generateHash(state.oldPassword, state.salt!),
          accessLevelErrorMessage: null,
          oldPasswordErrorMessage: null,
          passwordErrorMessage: null,
          confirmPasswordErrorMessage: null,
          status: FormStatus.submitting,
        ),
      );
    } else {
      // Form validation failed
      emit(state.copyWith(status: FormStatus.error));
    }
  }

  Future<void> _onLoadSaltAndHash(LoadSaltAndHashEvent event, Emitter<UserFormState> emit) async {
    try {
      emit(state.copyWith(
        salt: event.salt,
        passwordHash: event.passwordHash,
      ));
    } catch (e) {
      emit(state.copyWith(status: FormStatus.error));
    }
  }
}
