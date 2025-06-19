import 'package:easthardware_pms/presentation/cubit/navigation/navigation_cubit.dart';
import 'package:easthardware_pms/utils/boxed.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class TypedGoRoute<T> extends GoRoute {
  TypedGoRoute({
    required AppRoute<T> route,
    Widget Function(BuildContext, TypedGoRouterState<T>)? builder,
    super.name,
    super.pageBuilder,
    super.parentNavigatorKey,
    super.redirect,
    super.onExit,
    super.caseSensitive = true,
    super.routes = const <RouteBase>[],
  }) : super(
          path: route.path,
          builder: builder == null
              ? null
              : (context, state) {
                  final extra = state.extra;
                  if (extra is! T) {
                    throw ArgumentError(
                      'Expected extra to be of type $T, '
                      'but got ${extra.runtimeType}',
                    );
                  }

                  return builder.call(context, TypedGoRouterState<T>(state));
                },
        );
}

extension type const TypedGoRouterState<T>(GoRouterState state) implements GoRouterState {
  /// The extra data passed to the route.
  T get extra => state.extra as T;
}

/// A zero-cost compile-time wrapper for a string path.
///   This is used to define and use routes in a type-safe manner.
extension type const AppRoute<T>(String path) {
  List<String> get segments => path.split('/').where((s) => s.isNotEmpty).toList();
}

extension SafeNavigationExtension on BuildContext {
  void navigate(AppRoute<Null> route) {
    final cubit = read<NavigationCubit>();

    if (cubit.state.route != route) {
      cubit.navigateTo(route, extra: null);
    } else {
      printBoxed("Already on the route: $route", "context.navigate");
    }
  }

  /// Navigates to a route which requires an extra parameter.
  ///   The [extra] parameter should match the type signature of the route.
  void navigateWithExtra<E extends Object, R extends AppRoute<E>>(R route, E extra) {
    final cubit = read<NavigationCubit>();

    if (cubit.state.route != route || cubit.state.extra != extra) {
      cubit.navigateTo(route, extra: extra);
    } else {
      printBoxed(
        "Already on the route with the same extra: $extra",
        "context.navigateWithExtra",
      );
    }
  }
}
