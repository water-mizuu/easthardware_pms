import 'package:easthardware_pms/domain/enums/enums.dart';
import 'package:easthardware_pms/presentation/bloc/authentication/authentication/authentication_bloc.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

extension ContextIsStaff on BuildContext {
  bool get isStaff {
    final user = read<AuthenticationBloc>().state.user;

    return user != null && user.accessLevel == AccessLevel.staff;
  }

  bool get isAdmin {
    final user = read<AuthenticationBloc>().state.user;

    return user != null && user.accessLevel == AccessLevel.administrator;
  }

  bool get isLoggedIn {
    final user = read<AuthenticationBloc>().state.user;

    return user != null;
  }
}
