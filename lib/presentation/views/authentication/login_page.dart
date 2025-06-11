import 'package:easthardware_pms/domain/enums/enums.dart';
import 'package:easthardware_pms/presentation/bloc/authentication/authentication/authentication_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/authentication/login_form/login_form_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/security/user_list/user_list_bloc.dart';
import 'package:easthardware_pms/presentation/router/app_routes.dart';
import 'package:easthardware_pms/presentation/views/authentication/login_form.dart';
import 'package:easthardware_pms/utils/typed_routes.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        /// This listener handles the authentication state changes relevant
        ///   to the login form. Basically, if the [status] becomes [.loggingIn],
        ///   then changes to a different status, it means that something happened.
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

              /// If we are successful, we want to do other side effects here.
              ///   Usual effects such as navigation is done in another part of the application.
              if (status == AuthenticationStatus.success) {
                final userId = user!.id;
                assert(userId != null, "User ID must not be null after successful login.");

                context.read<UserListBloc>().add(UserLoggedInEvent(userId!));
                return;
              }

              /// If we are not successful, we want to handle the failure.
              if (status == AuthenticationStatus.failure) {
                if (authState.loginAttempts >= 3) {
                  context.navigateWithExtra(
                    AppRoutes.resetPassword,
                    context.read<LoginFormBloc>().state.username,
                  );
                }

                context.read<LoginFormBloc>().add(LoginFormSubmitFailed(authState.formErrors));
                return;
              }

              throw Error();
            } finally {
              context.read<LoginFormBloc>().add(LoginFormReturned());
            }
          },
        ),
        BlocListener<AuthenticationBloc, AuthenticationState>(
          listenWhen: (p, c) => p.status != c.status,
          listener: (context, state) {
            if (state.status == AuthenticationStatus.success) {
              context.read<LoginFormBloc>().add(LoginFormResetEvent());
            }
          },
        ),
        BlocListener<LoginFormBloc, LoginFormState>(
          listenWhen: (p, c) => p.status != c.status,
          listener: (context, state) {
            if (kDebugMode) {
              print('LoginFormBloc: State changed: ${state.status}');
            }
            if (state.status == FormStatus.submitting) {
              final event = AuthenticationLoginEvent(
                username: state.username,
                password: state.password,
              );

              context.read<AuthenticationBloc>().add(event);
            }
          },
        ),
      ],
      child: ColoredBox(
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
      ),
    );
  }
}
