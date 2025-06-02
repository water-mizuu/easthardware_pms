import 'dart:io' show Platform;

import 'package:easthardware_pms/presentation/bloc/navigation/navigation_cubit.dart';
import 'package:easthardware_pms/presentation/router/app_routes.dart';
import 'package:easthardware_pms/presentation/widgets/brand/navrail_header.dart';
import 'package:easthardware_pms/presentation/widgets/helper/nav_rail_route_index_mapper.dart';
import 'package:easthardware_pms/presentation/widgets/layout_mode_provider.dart';
import 'package:easthardware_pms/presentation/widgets/title_bar.dart';
import 'package:easthardware_pms/utils/boxed.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:scroll_animator/scroll_animator.dart';

class AdminNavigationScaffold extends StatelessWidget {
  const AdminNavigationScaffold(this.shell, this.children, {super.key});

  final StatefulNavigationShell shell;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    var widget = LayoutBuilder(
      builder: (context, constraints) {
        final mode = switch (constraints.maxWidth) {
          >= 1200 => PaneDisplayMode.open,
          >= 600 => PaneDisplayMode.compact,
          _ => PaneDisplayMode.minimal,
        };

        return AdminNavigationView(
          mode: mode,
          child: children[shell.currentIndex],
        );
      },
    ) as Widget;

    /// If the platform is macOS, we need to account for the menu buttons
    if (Platform.isMacOS) {
      widget = Container(
        color: FluentTheme.of(context).micaBackgroundColor,
        padding: const EdgeInsets.only(top: macOSTitleBarHeight),
        child: widget,
      );
    }

    return widget;
  }
}

class AdminNavigationView extends StatefulWidget {
  const AdminNavigationView({
    super.key,
    required this.mode,
    required this.child,
  });

  final PaneDisplayMode mode;
  final Widget child;

  @override
  State<AdminNavigationView> createState() => _AdminNavigationViewState();
}

class _AdminNavigationViewState extends State<AdminNavigationView> {
  late final NavRailRouteIndexMapper _routeIndexMapper;
  late final AnimatedScrollController _scrollController;
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();

    _routeIndexMapper = NavRailRouteIndexMapper(items: _navigationItems);
    _scrollController = AnimatedScrollController(animationFactory: const ChromiumEaseInOut());
    _selectedIndex = 0;
  }

  @override
  void dispose() {
    _scrollController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        /// Here, we only listen to the NavigationCubit to update the selected index
        ///   based on the current route.
        BlocListener<NavigationCubit, NavigationState>(
          listener: (context, state) {
            /// We update the selected index based on the current route.
            final index = _routeIndexMapper.getIndexFromRoute(state.route);
            if (index != null) {
              _selectedIndex = index;
            }
          },
        ),
      ],
      child: NavigationView(
        /// By giving the widget a ValueKey, it makes the widget create
        ///   a new instance whenever the mode changes. This is important
        ///   because the NavigationView animates its transition when in debugMode,
        ///   and it throws assertion errors. In release mode, this is not necessary.
        key: kDebugMode ? ValueKey(widget.mode) : null,
        clipBehavior: Clip.hardEdge,

        /// The pane body builder creates the body of the window.
        ///   It is essentially the right side of the navigation view.
        paneBodyBuilder: (item, body) {
          var widget = LayoutModeProvider(child: this.widget.child) as Widget;

          /// We only impose a padding on the child if the title bar is present
          ///   and we are in windows.
          if (Platform.isWindows) {
            widget = Padding(
              padding: const EdgeInsets.only(top: windowsTitleBarHeight),
              child: widget,
            );
          }

          return widget;
        },

        /// The pane represents the left side of the navigation view.
        ///   It contains the navigation items and the header.
        pane: NavigationPane(
          header: const LogoRow(),
          scrollController: _scrollController,
          selected: _selectedIndex,
          displayMode: widget.mode,
          onItemPressed: (index) {
            if ([1, 12].contains(index)) {
              index++;
            }
            if (index == 16) return;

            final probablyRoute = _routeIndexMapper.getRouteFromIndex(index);
            if (probablyRoute case final AppRoute<void> route) {
              context.navigate(route);
              return;
            }

            if (kDebugMode) {
              printBoxed(
                "Tried to navigate to a route which requires a parameter: $probablyRoute",
                "AdminNavigationView",
              );
            }
          },
          items: _navigationItems,
        ),
      ),
    );
  }

  static final List<NavigationPaneItem> _navigationItems = [
    _createNavItem(
      icon: FluentIcons.dynamic_list,
      title: "Dashboard",
      route: AppRoutes.staffDashboard,
    ),
    PaneItemSeparator(),
    _createNavItem(
      icon: FluentIcons.product,
      title: "Inventory",
      items: _getInventorySubItems(),
      route: AppRoutes.inventoryPage,
    ),
    _createNavItem(
      icon: FluentIcons.text_document,
      title: 'Billing',
      items: _getBillingSubItems(),
      route: AppRoutes.billingPage,
    ),
    _createNavItem(
      icon: FluentIcons.bill,
      title: 'Orders',
      items: _getOrderSubItems(),
      route: AppRoutes.orderPage,
    ),
    _createNavItem(
      icon: FluentIcons.bar_chart_vertical_fill,
      title: 'Reports',
      route: AppRoutes.reportsPage,
    ),
    _createNavItem(
      icon: FluentIcons.local_admin,
      title: 'Security',
      items: _getSecuritySubItems(),
      route: AppRoutes.admin,
    )
    //
  ];

  static List<NavigationPaneItem> _getInventorySubItems() {
    return [
      _createNavItem(
        icon: FluentIcons.product_list,
        title: "List of Products",
        route: AppRoutes.inventoryPage,
      ),
      _createNavItem(
        icon: FluentIcons.product_release,
        title: "Register Product",
        route: AppRoutes.createProductPage,
      ),
      _createNavItem(
        icon: FluentIcons.product_catalog,
        title: "Manage Categories",
        route: AppRoutes.categoriesPage,
      ),
    ];
  }

  static List<NavigationPaneItem> _getBillingSubItems() {
    return [
      _createNavItem(
        icon: FluentIcons.text_document,
        title: "Invoice List",
        route: AppRoutes.billingPage,
      ),
      _createNavItem(
        icon: FluentIcons.text_document_edit,
        title: "Payments",
        route: AppRoutes.billingPage,
      ),
    ];
  }

  static List<NavigationPaneItem> _getOrderSubItems() {
    return [
      _createNavItem(
        icon: FluentIcons.bill,
        title: 'Orders List',
        route: AppRoutes.orderPage,
      ),
      _createNavItem(
        icon: FluentIcons.reservation_orders,
        title: 'Manage Expense Type',
        route: AppRoutes.orderPage,
      ),
    ];
  }

  static List<NavigationPaneItem> _getSecuritySubItems() {
    return [
      _createNavItem(
        icon: FluentIcons.contact_list,
        title: 'List of Users',
        route: AppRoutes.usersPage,
      ),
      _createNavItem(
        icon: FluentIcons.add_friend,
        title: 'Register User',
        route: AppRoutes.createUserPage,
      ),
      _createNavItem(
        icon: FluentIcons.user_window,
        title: 'User Logs',
        route: AppRoutes.userLogsPage,
      ),
      _createNavItem(
        icon: FluentIcons.leave,
        title: 'Log Out',
        route: AppRoutes.login,
        onTap: () {
          if (kDebugMode) {
            print('Log out');
          }
        },
      ),
    ];
  }

  static NavigationPaneItem _createNavItem({
    required IconData icon,
    required String title,
    required AppRoute route,
    List<NavigationPaneItem>? items,
    VoidCallback? onTap,
  }) {
    if (items != null && items.isNotEmpty) {
      return PaneItemExpander(
        icon: Icon(icon),
        title: Text(title),
        items: items,

        /// A little hack to allow the [RouteIndexMapper] to access the route linked
        ///   to this item.
        infoBadge: Transform.scale(scale: 0.0, child: RouteText(route)),
        body: const SizedBox.shrink(),
      );
    } else {
      return PaneItem(
        icon: Icon(icon),
        title: Text(title),

        /// A little hack to allow the [RouteIndexMapper] to access the route linked
        ///   to this item.
        infoBadge: Transform.scale(scale: 0.0, child: RouteText(route)),
        body: const SizedBox.shrink(),
        onTap: onTap,
      );
    }
  }
}

class RouteText extends Text {
  const RouteText(AppRoute data, {super.key}) : super(data as String);
}
