import 'package:easthardware_pms/presentation/router/app_router.dart';
import 'package:easthardware_pms/utils/boxed.dart';
import 'package:easthardware_pms/utils/typed_routes.dart';
import 'package:easthardware_pms/utils/undefined.dart';
import 'package:equatable/equatable.dart';
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
