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
    final routeToIndex = <AppRoute<Null>, int>{};
    final indexToRoute = <int, AppRoute<Null>>{};
    for (var i = 0; i < expandedItems.length; i++) {
      final badge = expandedItems[i].infoBadge;
      if (badge case Transform(child: RouteText(:final AppRoute<Null> data))) {
        if (kDebugMode) {
          print('Mapping route: $data to index: $i');
        }

        routeToIndex[data] = i;
        indexToRoute[i] = data;
      }
    }

    return NavRailRouteIndexMapper._(routeToIndex, indexToRoute);
  }

  const NavRailRouteIndexMapper._(this._routeToIndex, this._indexToRoute);

  final Map<AppRoute<Null>, int> _routeToIndex;
  final Map<int, AppRoute<Null>> _indexToRoute;

  AppRoute<Null>? getRouteFromIndex(int index) {
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
