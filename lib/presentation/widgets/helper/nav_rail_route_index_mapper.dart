import 'package:easthardware_pms/presentation/router/app_routes.dart';
import 'package:easthardware_pms/presentation/views/navigation/admin_navigation_scaffold.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart';

/// This class maps routes to their respective indices according to the navigation pane items.
///   It is used to determine the index of a route in the navigation pane and vice versa.
class NavRailRouteIndexMapper {
  factory NavRailRouteIndexMapper({
    required List<NavigationPaneItem> items,
  }) {
    final expandedItems = items.expandItems().toList();
    final routeToIndex = <AppRoute, int>{};
    final indexToRoute = <int, AppRoute>{};
    for (var i = 0; i < expandedItems.length; i++) {
      if (expandedItems[i].infoBadge case Transform(child: RouteText(:final data))) {
        if (kDebugMode) {
          print('Mapping route: $data to index: $i');
        }

        final route = data as AppRoute;
        routeToIndex[route] = i;
        indexToRoute[i] = route;
      }
    }

    return NavRailRouteIndexMapper._(routeToIndex, indexToRoute);
  }

  const NavRailRouteIndexMapper._(this._routeToIndex, this._indexToRoute);

  final Map<AppRoute, int> _routeToIndex;
  final Map<int, AppRoute> _indexToRoute;

  AppRoute? getRouteFromIndex(int index) {
    return _indexToRoute[index];
  }

  int? getIndexFromRoute(AppRoute route) {
    return _routeToIndex[route];
  }
}

extension on Iterable<NavigationPaneItem> {
  /// Flattens the list of NavigationPaneItems, expanding any PaneItemExpander items.
  Iterable<PaneItem> expandItems() {
    AppRoutes;
    return expand(
      (item) => item is PaneItemExpander //
          ? [item, ...item.items.expandItems()]
          : item is PaneItem
              ? [item]
              : [],
    );
  }
}
