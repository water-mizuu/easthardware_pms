import 'dart:async';

import 'package:easthardware_pms/domain/enums/enums.dart';
import 'package:easthardware_pms/presentation/bloc/authentication/authentication/authentication_bloc.dart';
import 'package:easthardware_pms/utils/duration.dart';
import 'package:easthardware_pms/utils/undefined.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'login_form_event.dart';
part 'login_form_state.dart';

class LoginFormBloc extends Bloc<LoginFormEvent, LoginFormState> {
  LoginFormBloc(super.initialState) : formKey = GlobalKey<FormState>() {
    on<LoginFormUsernameChanged>(_onUsernameChanged);
    on<LoginFormPasswordChanged>(_onPasswordChanged);
    on<LoginFormButtonPressed>(_onButtonPressed);
    on<LoginFormReturned>(_onFormReturned);
    on<LoginFormResetEvent>(_onReset);
    on<LoginFormSubmitFailed>(_onSubmitFailed);
    on<LoginFormClearErrors>(_onClearErrors);
  }
  final GlobalKey<FormState> formKey;

  @override
  void onEvent(LoginFormEvent event) {
    super.onEvent(event);

    if (kDebugMode) {
      print('LoginFormBloc: Event received: ${event.runtimeType}');
    }
  }

  void _onUsernameChanged(LoginFormUsernameChanged event, Emitter emit) {
    final username = event.username;
    return emit(state.copyWith(username: username, usernameError: null));
  }

  void _onPasswordChanged(LoginFormPasswordChanged event, Emitter emit) {
    final password = event.password;
    return emit(state.copyWith(password: password, passwordError: null));
  }

  Future<void> _onButtonPressed(LoginFormButtonPressed event, Emitter emit) async {
    emit(state.copyWith(status: FormStatus.validating));

    assert(formKey.currentState != null, 'Form key must be initialized before validation.');
    if (formKey.currentState case final FormState formState when formState.validate()) {
      await Future.delayed(100.milliseconds);
      emit(state.copyWith(status: FormStatus.submitting));
    } else {
      emit(state.copyWith(status: FormStatus.error));
    }
  }

  Future<void> _onFormReturned(LoginFormReturned event, Emitter emit) async {
    emit(state.copyWith(status: FormStatus.initial));
  }

  void _onReset(LoginFormResetEvent event, Emitter emit) {
    emit(const LoginFormState());
  }

  void _onSubmitFailed(LoginFormSubmitFailed event, Emitter<LoginFormState> emit) {
    emit(state.copyWith(
      usernameError: event.errors //
          .where((error) => error.target == FormElement.username)
          .firstOrNull
          ?.message,
      passwordError: event.errors //
          .where((error) => error.target == FormElement.password)
          .firstOrNull
          ?.message,
    ));
  }

  Future<void> _onClearErrors(LoginFormClearErrors event, Emitter<LoginFormState> emit) async {
    emit(state.copyWith(
      usernameError: null,
      passwordError: null,
    ));
  }
}
