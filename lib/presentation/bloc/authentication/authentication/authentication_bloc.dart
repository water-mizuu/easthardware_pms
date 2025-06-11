import 'dart:async';

import 'package:easthardware_pms/domain/errors/exceptions.dart';
import 'package:easthardware_pms/domain/models/user.dart';
import 'package:easthardware_pms/domain/repository/authentication_repository.dart';
import 'package:easthardware_pms/utils/boxed.dart';
import 'package:easthardware_pms/utils/undefined.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'authentication_event.dart';
part 'authentication_state.dart';

class AuthenticationBloc extends Bloc<AuthenticationEvent, AuthenticationState> {
  AuthenticationBloc(this._repository, AuthenticationState initialState) : super(initialState) {
    on<AuthenticationLoginEvent>(_onLogin);
    on<AuthenticationLogoutEvent>(_onLogout);
    on<AuthenticationPostLogoutEvent>(_onPostLogout);
    on<AuthenticationResetEvent>(_onReset);
  }

  final AuthenticationRepository _repository;

  @override
  Future<void> close() async {
    if (kDebugMode) {
      printBoxed("Closed the authentication bloc.", "AuthenticationBloc");
    }

    super.close();
  }

  @override
  void onEvent(AuthenticationEvent event) {
    if (kDebugMode) {
      print("[$AuthenticationBloc] $event");
    }

    switch (event) {
      case AuthenticationLoginEvent():
        break;
      case AuthenticationLogoutEvent():
        break;
      case AuthenticationPostLogoutEvent():
        break;
      case AuthenticationResetEvent():
        break;
    }

    super.onEvent(event);
  }

  Future<void> _onLogin(AuthenticationLoginEvent event, Emitter emit) async {
    emit(state.copyWith(status: AuthenticationStatus.loggingIn));
    await Future.delayed(Duration.zero);
    if (isClosed) return;

    try {
      final user = await _repository.logIn(username: event.username, password: event.password);
      emit(state.copyWith(
        status: AuthenticationStatus.success,
        user: user,
        loginAttempts: 0,
        lastUsername: null,
      ));
    } on LoginFormException catch (e) {
      if (kDebugMode) {
        print("LoginFormException: $e");
      }

      final newLoginAttempts = switch (e.code) {
        /// If the user does not exist, we reset the login attempts.
        ///   This is because we do not want to trigger the reset password.
        LoginFormExceptionCode.userDoesNotExist => 0,

        /// If the user is already logged in, we do not need to increment the login attempts.
        ///   We actually reset it.
        LoginFormExceptionCode.userAlreadyLoggedIn => 0,

        /// If the last username is the same as the current one,
        ///   increment the login attempts.
        LoginFormExceptionCode.invalidPassword => //
          state.lastUsername == event.username //
              ? state.loginAttempts + 1
              : 1,
      };

      emit(
        state.copyWith(
          status: AuthenticationStatus.failure,
          loginAttempts: newLoginAttempts,
          lastUsername: event.username,
          errors: e.errors,
        ),
      );
    } catch (e) {
      if (kDebugMode) {
        print("Unexpected error during login: $e");
      }

      emit(state.copyWith(status: AuthenticationStatus.failure, errorMessage: e.toString()));
    }
  }

  Future<void> _onLogout(
    AuthenticationLogoutEvent event,
    Emitter<AuthenticationState> emit,
  ) async {
    emit(state.copyWith(status: AuthenticationStatus.loggingOut));
    await Future.delayed(Duration.zero);
    if (isClosed) return;

    assert(state.user != null, "User must be logged in to log out.");
    final userId = state.user?.id;
    assert(userId != null, "User ID must not be null when logging out.");

    try {
      _repository.logOut(userId: userId!);

      emit(
        state.copyWith(
          status: AuthenticationStatus.success,
          user: null,
          previousUser: state.user,
        ),
      );
    } catch (e) {
      emit(state.copyWith(status: AuthenticationStatus.failure));
    }
  }

  Future<void> _onPostLogout(
    AuthenticationPostLogoutEvent event,
    Emitter<AuthenticationState> emit,
  ) async {
    emit(state.copyWith(previousUser: null));
  }

  Future<void> _onReset(AuthenticationResetEvent event, Emitter<AuthenticationState> emit) async {
    emit(state.copyWith(
      loginAttempts: 0,
      user: null,
      previousUser: null,
      errors: const {},
    ));
  }
}
