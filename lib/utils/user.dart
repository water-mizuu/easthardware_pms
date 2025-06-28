import 'package:easthardware_pms/domain/enums/enums.dart';
import 'package:easthardware_pms/presentation/bloc/authentication/authentication/authentication_bloc.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

extension UserExtension on BuildContext {
  AccessLevel? watchAccessLevel() {
    return watch<AuthenticationBloc>().state.user?.accessLevel;
  }

  AccessLevel? get readLevel {
    return read<AuthenticationBloc>().state.user?.accessLevel;
  }
}

extension AccessLevelGettersExtension on AccessLevel? {
  bool get isAdministrator => this == AccessLevel.administrator;
  bool get isStaff => this == AccessLevel.staff;

  bool get isAuthenticated => this != null;
}
