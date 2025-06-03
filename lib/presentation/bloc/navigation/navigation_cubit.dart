import 'package:easthardware_pms/presentation/router/app_router.dart';
import 'package:easthardware_pms/presentation/router/app_routes.dart';
import 'package:easthardware_pms/utils/boxed.dart';
import 'package:easthardware_pms/utils/undefined.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'navigation_state.dart';

class NavigationCubit extends Cubit<NavigationState> {
  NavigationCubit() : super(const NavigationState(route: initialLocation));

  void navigateTo(AppRoute route, {Object? extra}) {
    if (kDebugMode) {
      printBoxed("Navigating to: $route with extra: $extra", "NavigationCubit.navigateTo");
    }
    emit(NavigationState(route: route, extra: extra));
  }
}

extension SafeNavigationExtension on BuildContext {
  void navigate(AppRoute<void> route) {
    final cubit = read<NavigationCubit>();

    if (cubit.state.route != route) {
      cubit.navigateTo(route, extra: null);
    } else {
      if (kDebugMode) {
        printBoxed("Already on the route: $route", "context.navigate");
      }
    }
  }

  /// Navigates to a route which requires an extra parameter.
  ///   The [extra] parameter should match the type signature of the route.
  void navigateWithExtra<E extends Object, R extends AppRoute<E>>(R route, E extra) {
    final cubit = read<NavigationCubit>();

    if (cubit.state.route != route || cubit.state.extra != extra) {
      cubit.navigateTo(route, extra: extra);
    } else {
      if (kDebugMode) {
        printBoxed(
          "Already on the route with the same extra: $extra",
          "context.navigateWithExtra",
        );
      }
    }
  }
}
