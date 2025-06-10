import 'package:easthardware_pms/app/dependency_injector.dart';
import 'package:easthardware_pms/domain/enums/enums.dart';
import 'package:easthardware_pms/presentation/bloc/authentication/'
    'authentication/authentication_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/navigation/navigation_cubit.dart';
import 'package:easthardware_pms/presentation/bloc/security/user_log_list/user_log_list_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/server/server_bloc.dart';
import 'package:easthardware_pms/presentation/router/app_router.dart';
import 'package:easthardware_pms/presentation/router/app_routes.dart';
import 'package:easthardware_pms/presentation/widgets/is_full_screen_provider.dart';
import 'package:easthardware_pms/presentation/widgets/title_bar.dart';
import 'package:easthardware_pms/utils/boxed.dart';
import 'package:easthardware_pms/utils/typed_routes.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<StatefulWidget> createState() => _AppState();
}

class _AppState extends State<App> {
  late final DependencyInjector di;
  late FluentThemeData theme;

  List<SingleChildWidget> get blocListeners {
    return [
      /// This listener automatically initializes the dependency injector
      ///   whenever the database helper is updated.
      /// This happens when the user decides to change the database or server type.
      BlocListener<ServerBloc, ServerState>(
        listenWhen: (p, c) => p.databaseHelper != c.databaseHelper,
        listener: (context, state) {
          di.initialize(databaseHelper: state.databaseHelper);
        },
      ),

      /// This listener automatically refreshes parts of the app whenever
      ///   the server state is updated
      BlocListener<ServerBloc, ServerState>(
        listenWhen: (p, c) => p.lastUpdated != c.lastUpdated,
        listener: (context, state) {
          di.markNeedsRefresh();
        },
      ),

      /// Listen to the server bloc for bottom text updates.
      ///   This is used to display messages at the bottom of the app.
      BlocListener<ServerBloc, ServerState>(
        listenWhen: (p, c) => p.bottomText != c.bottomText && c.bottomText != null,
        listener: (context, state) {
          final bottomText = state.bottomText!;
          if (bottomText.isNotEmpty) {
            di.bottomText.value = bottomText;
          }
        },
      ),

      /// Update the router whenever the navigation state changes.
      BlocListener<NavigationCubit, NavigationState>(
        listener: (context, state) {
          router.go(state.route.path, extra: state.extra);
        },
      ),

      /// Listen to the authentication bloc.
      ///   This listener handles the changes in the stored user.
      ///   It makes it simpler to navigate to the correct page based on the user's access level.
      ///   However, order is not guaranteed.
      BlocListener<AuthenticationBloc, AuthenticationState>(
        listenWhen: (p, c) => p.user != c.user,
        listener: (context, state) {
          final user = state.user;

          switch (user?.accessLevel) {
            case null: // User is not authenticated.
              context.navigate(AppRoutes.login);
            case AccessLevel.staff:
              context.navigate(AppRoutes.staff.dashboard);
            case AccessLevel.administrator:
              context.navigate(AppRoutes.admin.dashboard);
          }
        },
      ),

      BlocListener<AuthenticationBloc, AuthenticationState>(
        listenWhen: (p, c) =>
            p.user == null && c.user != null || // User logged in
            p.user != null && c.user == null, // User logged out
        listener: (context, state) {
          final didUserLogIn = state.user != null;
          if (didUserLogIn) {
            if (kDebugMode) {
              printBoxed("User logged out.", "AuthenticationBloc");
            }
            // If the user logged in, we need to update the user log list.
            final user = state.user!;
            context.read<UserLogListBloc>().add(AddLoginEvent(user));
          } else {
            if (kDebugMode) {
              printBoxed("User logged out.", "AuthenticationBloc");
            }
            // If the user logged out, we need to update the user log list.
            final user = context.read<AuthenticationBloc>().state.previousUser;
            assert(user != null, "Log out event must have saved a previousUser.");

            context.read<UserLogListBloc>().add(AddLogoutEvent(user!));
            context.read<AuthenticationBloc>().add(const AuthenticationPostLogoutEvent());
          }
        },
      ),
    ];
  }

  @override
  void initState() {
    super.initState();

    theme = FluentThemeData.light().copyWith(cardColor: Colors.white);
    di = DependencyInjector()..initialize();
    di.addListener(_handleDependencyInjectorChanges);
  }

  @override
  void dispose() {
    di.removeListener(_handleDependencyInjectorChanges);
    di.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: di.inject(),
      builder: (context, child) {
        return MultiBlocListener(
          listeners: blocListeners,
          child: FluentTheme(
            data: theme,
            child: IsFullScreen.provider(
              child: TitleBar(
                child: FluentApp.router(
                  debugShowCheckedModeBanner: false,
                  routerConfig: router,
                  themeMode: ThemeMode.dark,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _handleDependencyInjectorChanges() {
    setState(() {});
  }
}
