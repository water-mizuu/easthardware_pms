import 'package:easthardware_pms/domain/enums/enums.dart';
import 'package:easthardware_pms/presentation/bloc/authentication/authentication/authentication_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/authentication/login_form/login_form_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/security/user_list/user_list_bloc.dart';
import 'package:easthardware_pms/presentation/router/app_routes.dart';
import 'package:easthardware_pms/presentation/views/authentication/login_form.dart';
import 'package:easthardware_pms/utils/boxed.dart';
import 'package:easthardware_pms/utils/typed_routes.dart';
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
      /// this bloc is for logging in.
      BlocListener<AuthenticationBloc, AuthenticationState>(
        listenWhen: (p, c) =>
            p.status == AuthenticationStatus.loggingIn &&
            (p.status != c.status || //
                p.user != c.user ||
                p.loginAttempts != c.loginAttempts),
        //
        listener: (context, authState) {
          final status = authState.status;
          final user = authState.user;

          try {
            assert(
              {AuthenticationStatus.success, AuthenticationStatus.failure}.contains(status),
              "After logging in, the status must be either success or failure.",
            );
            //

            if (status == AuthenticationStatus.success) {
              final userId = user!.id;
              assert(userId != null, "User ID must not be null after successful login.");

              if (kDebugMode) {
                printBoxed("User logged in: ${user.username} (ID: $userId)", "User Login");
              }

              /// Logging the login is now handled in a different part of the tree,
              ///   so we don't want to log it here.
              context.read<UserListBloc>().add(UserLoggedInEvent(userId!));

              return;
            }

            if (status == AuthenticationStatus.failure) {
              if (authState.loginAttempts >= 3) {
                context.navigateWithExtra(AppRoutes.resetPassword, loginFormBloc.state.username);
              }

              context.read<LoginFormBloc>().add(LoginFormSubmitFailed(authState.errors));

              return;
            }

            throw UnreachableError();
          } finally {
            loginFormBloc.add(LoginFormReturned());
          }
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

final class UnreachableError extends Error {}
