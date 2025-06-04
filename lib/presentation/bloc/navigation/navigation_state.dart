part of 'navigation_cubit.dart';

final class NavigationState with EquatableMixin {
  const NavigationState({required this.route, this.extra});

  final AppRoute route;
  final Object? extra;

  NavigationState Function({AppRoute route, Object? extra}) get copyWith {
    return ({
      Object? route = undefined,
      Object? extra = undefined,
    }) {
      return NavigationState(
        route: route.or(this.route),
        extra: extra.or(this.extra),
      );
    };
  }

  @override
  List<Object?> get props => [route, extra];
}
