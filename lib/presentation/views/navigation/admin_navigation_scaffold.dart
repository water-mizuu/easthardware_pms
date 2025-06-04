import 'dart:io' show Platform;

import 'package:easthardware_pms/presentation/bloc/authentication/authentication/authentication_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/navigation/navigation_cubit.dart';
import 'package:easthardware_pms/presentation/router/app_routes.dart';
import 'package:easthardware_pms/presentation/widgets/brand/navrail_header.dart';
import 'package:easthardware_pms/presentation/widgets/helper/nav_rail_route_index_mapper.dart';
import 'package:easthardware_pms/presentation/widgets/layout_mode_provider.dart';
import 'package:easthardware_pms/presentation/widgets/title_bar.dart';
import 'package:easthardware_pms/utils/boxed.dart';
import 'package:easthardware_pms/utils/typed_routes.dart';
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

    _routeIndexMapper = NavRailRouteIndexMapper(items: _navigationItems(context));
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
          listenWhen: (p, c) => p.route != c.route,
          listener: (context, state) {
            /// We update the selected index based on the current route.
            final route = state.route;
            if (route is! AppRoute<Null>) return;

            final index = _routeIndexMapper.getIndexFromRoute(route);
            if (index == null) return;

            _selectedIndex = index;
          },
        ),
      ],
      child: NavigationView(
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
          toggleable: false,
          displayMode: widget.mode,
          onItemPressed: (index) {
            final probablyRoute = _routeIndexMapper.getRouteFromIndex(index);
            if (probablyRoute case null) {
              if (kDebugMode) {
                printBoxed(
                  "Tried to navigate to a route which does not exist: $probablyRoute",
                  "AdminNavigationView",
                );
              }
              return;
            }

            if (probablyRoute case final AppRoute<Null> route) {
              context.navigate(route);
              return;
            }
          },
          items: _navigationItems(context),
          footerItems: _footerItems(context),
        ),
      ),
    );
  }

  static List<NavigationPaneItem> _navigationItems(BuildContext context) {
    return [
      _navItem(
        icon: FluentIcons.dynamic_list,
        title: "Dashboard",
        route: AppRoutes.admin.dashboard,
      ),
      PaneItemSeparator(),
      _navItem(
        icon: FluentIcons.product,
        title: "Inventory",
        route: AppRoutes.admin.inventory,
        items: [
          _navItem(
            icon: FluentIcons.product_list,
            title: "List of Products",
            route: AppRoutes.admin.inventory,
          ),
          _navItem(
            icon: FluentIcons.product_release,
            title: "Register Product",
            route: AppRoutes.admin.createProduct,
          ),
          _navItem(
            icon: FluentIcons.product_catalog,
            title: "Manage Categories",
            route: AppRoutes.admin.categories,
          ),
        ],
      ),
      _navItem(
        icon: FluentIcons.text_document,
        title: 'Billing',
        route: AppRoutes.admin.billing,
        items: [
          _navItem(
            icon: FluentIcons.text_document,
            title: "Invoice List",
            route: AppRoutes.admin.billing,
          ),
          _navItem(
            icon: FluentIcons.text_document_edit,
            title: "Create Invoice",
            route: AppRoutes.admin.createInvoice,
          ),
        ],
      ),
      _navItem(
        icon: FluentIcons.bill,
        title: 'Orders',
        // route: AppRoutes.orderPage,
        items: [
          _navItem(
            icon: FluentIcons.bill,
            title: 'Orders List',
            route: AppRoutes.admin.order,
          ),
          _navItem(
            icon: FluentIcons.reservation_orders,
            title: 'Manage Expense Type',
            // route: AppRoutes.orderPage,
          ),
        ],
      ),
      _navItem(
        icon: FluentIcons.bar_chart_vertical_fill,
        title: 'Reports',
        // route: AppRoutes.reportsPage,
      ),
      _navItem(
        icon: FluentIcons.local_admin,
        title: 'Security',
        // route: AppRoutes.admin.userLogs,
        items: [
          _navItem(
            icon: FluentIcons.contact_list,
            title: 'List of Users',
            route: AppRoutes.admin.users,
          ),
          _navItem(
            icon: FluentIcons.add_friend,
            title: 'Register User',
            route: AppRoutes.admin.createUser,
          ),
          _navItem(
            icon: FluentIcons.user_window,
            title: 'User Logs',
            route: AppRoutes.admin.userLogs,
          ),
        ],
      ),
    ];
  }

  static List<NavigationPaneItem> _footerItems(BuildContext context) {
    return [
      _navItem(
        icon: FluentIcons.leave,
        title: 'Log Out',
        onTap: () {
          context.read<AuthenticationBloc>().add(const AuthenticationLogoutEvent());
        },
      ),
    ];
  }

  static NavigationPaneItem _navItem({
    required IconData icon,
    required String title,
    AppRoute? route,
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
        infoBadge: route == null ? null : Transform.scale(scale: 0.0, child: RouteText(route)),
        body: const SizedBox.shrink(),
      );
    } else {
      return PaneItem(
        icon: Icon(icon),
        title: Text(title),

        /// A little hack to allow the [RouteIndexMapper] to access the route linked
        ///   to this item.
        infoBadge: route == null ? null : Transform.scale(scale: 0.0, child: RouteText(route)),
        body: const SizedBox.shrink(),
        onTap: onTap,
      );
    }
  }
}

class RouteText extends Text {
  const RouteText(AppRoute data, {super.key}) : super(data as String);
}
