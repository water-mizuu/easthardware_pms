import 'package:easthardware_pms/domain/errors/exceptions.dart';
import 'package:easthardware_pms/domain/models/user.dart';
import 'package:easthardware_pms/domain/repository/authentication_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'authentication_event.dart';
part 'authentication_state.dart';

class AuthenticationBloc extends Bloc<AuthenticationEvent, AuthenticationState> {
  AuthenticationBloc(this._repository) : super(AuthenticationState()) {
    on<AuthenticationLoginEvent>(_onLogin);
    on<AuthenticationLogoutEvent>((event, emit) {});
  }

  final AuthenticationRepository _repository;

  @override
  void onEvent(AuthenticationEvent event) {
    super.onEvent(event);

    if (kDebugMode) {
      print("[$AuthenticationBloc] $event");
    }
  }

  void _onLogin(AuthenticationLoginEvent event, Emitter emit) async {
    emit(state.copyWith(status: AuthenticationStatus.loading));
    Future.delayed(Duration.zero);
    try {
      User user = await _repository.logIn(username: event.username, password: event.password);
      emit(state.copyWith(status: AuthenticationStatus.success, user: user));
    } on AuthenticationException catch (e) {
      if (kDebugMode) {
        print(e);
      }

      return emit(
        state.copyWith(
          status: AuthenticationStatus.failure,
          loginAttempts: state.loginAttempts + 1,
        ),
      );
    }
  }
}
