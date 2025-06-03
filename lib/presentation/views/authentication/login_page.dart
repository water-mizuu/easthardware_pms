import 'package:easthardware_pms/domain/enums/enums.dart';
import 'package:easthardware_pms/presentation/bloc/authentication/authentication/authentication_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/authentication/login_form/login_form_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/authentication/reset_form/reset_form_bloc.dart'
    as ResetPasswordPage;
import 'package:easthardware_pms/presentation/bloc/navigation/navigation_cubit.dart';
import 'package:easthardware_pms/presentation/bloc/security/user_log_list/user_log_list_bloc.dart';
import 'package:easthardware_pms/presentation/router/app_routes.dart';
import 'package:easthardware_pms/presentation/views/authentication/login_form.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  late final LoginFormBloc loginFormBloc;

  List<SingleChildWidget> get providers {
    return [
      BlocProvider.value(value: loginFormBloc),
    ];
  }

  List<BlocListener> get listeners {
    return [
      BlocListener<AuthenticationBloc, AuthenticationState>(
        listenWhen: (
          previous,
          current,
        ) =>
            previous.status != current.status ||
            previous.user != current.user ||
            previous.loginAttempts != current.loginAttempts,
        listener: (context, authState) {
          final status = authState.status;
          final user = authState.user;

          if (status == AuthenticationStatus.failure) {
            if (kDebugMode) {
              print(status);
            }
            if (authState.loginAttempts > 3) {
              context.navigate(AppRoutes.resetPassword);
            }
          } else if (status == AuthenticationStatus.success) {
            if (user?.accessLevel == AccessLevel.administrator) {
              context.navigate(AppRoutes.admin);
            } else if (user?.accessLevel == AccessLevel.staff) {
              context.navigate(AppRoutes.admin);
            }
            context.read<UserLogListBloc>().add(AddLoginEvent(user!));
          }
          loginFormBloc.add(LoginFormReturned());
        },
      ),
      BlocListener<AuthenticationBloc, AuthenticationState>(
        listener: (context, state) {
          if (state.status == AuthenticationStatus.success) {
            loginFormBloc.add(LoginFormResetEvent());
          }
        },
      ),
      BlocListener<LoginFormBloc, LoginFormState>(
        bloc: loginFormBloc,
        listener: (context, state) {
          if (state.status == FormStatus.submitting) {
            final event = AuthenticationLoginEvent(
              username: state.username,
              password: state.password,
            );

            context.read<AuthenticationBloc>().add(event);
            context
                .read<ResetPasswordPage.ResetFormBloc>()
                .setUsername(state.username);
          }
        },
      ),
    ];
  }

  @override
  void initState() {
    super.initState();

    loginFormBloc = LoginFormBloc();
  }

  @override
  void dispose() {
    loginFormBloc.close();

    super.dispose();
  }

  Widget buildWidget(BuildContext context) {
    return ColoredBox(
      color: FluentTheme.of(context).micaBackgroundColor,
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.max,
        children: [
          Row(
            children: [
              Spacer(),
              Expanded(child: LoginForm()),
              Spacer(),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: providers,
      child: MultiBlocListener(
        listeners: listeners,
        child: buildWidget(context),
      ),
    );
  }
}
