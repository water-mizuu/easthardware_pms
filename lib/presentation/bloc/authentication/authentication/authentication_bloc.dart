import 'dart:async';

import 'package:easthardware_pms/domain/errors/exceptions.dart';
import 'package:easthardware_pms/domain/models/user.dart';
import 'package:easthardware_pms/domain/repository/authentication_repository.dart';
import 'package:easthardware_pms/utils/undefined.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'authentication_event.dart';
part 'authentication_state.dart';

class AuthenticationBloc
    extends Bloc<AuthenticationEvent, AuthenticationState> {
  AuthenticationBloc(this._repository) : super(AuthenticationState()) {
    on<AuthenticationLoginEvent>(_onLogin);
    on<AuthenticationLogoutEvent>(_onLogout);
    on<AuthenticationPostLogoutEvent>(_onPostLogout);
  }

  final AuthenticationRepository _repository;

  @override
  void onEvent(AuthenticationEvent event) {
    super.onEvent(event);

    if (kDebugMode) {
      print("[$AuthenticationBloc] $event");
    }
  }

  Future<void> _onLogin(AuthenticationLoginEvent event, Emitter emit) async {
    emit(state.copyWith(status: AuthenticationStatus.loggingIn));
    await Future.delayed(Duration.zero);
    if (isClosed) return;

    try {
      final user = await _repository.logIn(
          username: event.username, password: event.password);
      emit(state.copyWith(
        status: AuthenticationStatus.success,
        user: user,
        loginAttempts: 0,
        lastUsername: null,
      ));
    }

    /// [AuthenticationException] is thrown when the password is invalid.
    on AuthenticationException catch (e) {
      if (kDebugMode) {
        print(e);
      }

      emit(
        state.copyWith(
          status: AuthenticationStatus.failure,
          loginAttempts: state.lastUsername == event.username
              ? state.loginAttempts + 1
              : 1,
          lastUsername: event.username,
        ),
      );
    }

    /// [DatabaseException] is thrown when the user is not found in the database.
    ///   OR the user is not allowed.
    on DatabaseException catch (e) {
      if (kDebugMode) {
        print("DatabaseException: $e");
      }

      emit(
        state.copyWith(
          status: AuthenticationStatus.failure,
          loginAttempts: 0,
          errors: [
            ErrorMessage(message: e.message, target: FormElement.username),
          ],
        ),
      );
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
}
