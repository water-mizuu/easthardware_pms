import 'package:easthardware_pms/presentation/views/navigation/common_side_panel_mixin.dart';
import 'package:easthardware_pms/utils/typed_routes.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart';

/// This class maps routes to their respective indices according to the navigation pane items.
///   It is used to determine the index of a route in the navigation pane and vice versa.
class NavRailRouteIndexMapper {
  factory NavRailRouteIndexMapper({required List<PaneItem> items}) {
    final routeToIndex = <AppRoute<Null>, int>{};
    final indexToRoute = <int, AppRoute<Null>>{};
    for (var i = 0; i < items.length; i++) {
      final badge = items[i].infoBadge;

      if (badge case SizedBox(child: RouteText(:final AppRoute<Null> data))) {
        routeToIndex[data] = i;
        indexToRoute[i] = data;
      } else if (badge case SizedBox(child: RouteText(:final AppRoute<Object> data))) {
        /// If the route is not null, then the user tried to put
        ///   a route with a non-nullable type in the navigation pane.

        if (kDebugMode) {
          print('Warning: Route $data is not nullable, but it was used in the navigation pane.');
        }
      }
    }

    return NavRailRouteIndexMapper._(
      UnmodifiableMap(Map.unmodifiable(routeToIndex)),
      UnmodifiableMap(Map.unmodifiable(indexToRoute)),
    );
  }

  const NavRailRouteIndexMapper._(this._routeToIndex, this._indexToRoute);

  final UnmodifiableMap<AppRoute<Null>, int> _routeToIndex;
  final UnmodifiableMap<int, AppRoute<Null>> _indexToRoute;

  AppRoute<Null>? getRouteFromIndex(int index) {
    return _indexToRoute[index];
  }

  int? getIndexFromRoute(AppRoute<Null> route) {
    return _routeToIndex[route];
  }
}

extension type const UnmodifiableMap<K, V>(Map<K, V> map) implements Map<K, V> {
  V? operator [](K key) => map[key];
}
