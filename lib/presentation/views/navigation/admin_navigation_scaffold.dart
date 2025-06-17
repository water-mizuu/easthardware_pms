import 'dart:io' show Platform;

import 'package:easthardware_pms/presentation/bloc/navigation/navigation_cubit.dart';
import 'package:easthardware_pms/presentation/router/app_routes.dart';
import 'package:easthardware_pms/presentation/views/navigation/common_side_panel_mixin.dart';
import 'package:easthardware_pms/presentation/widgets/brand/navrail_header.dart';
import 'package:easthardware_pms/presentation/widgets/helper/nav_rail_route_index_mapper.dart';
import 'package:easthardware_pms/presentation/widgets/is_full_screen_provider.dart';
import 'package:easthardware_pms/presentation/widgets/layout_mode_provider.dart';
import 'package:easthardware_pms/presentation/widgets/title_bar.dart';
import 'package:easthardware_pms/utils/boxed.dart';
import 'package:easthardware_pms/utils/typed_routes.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:scroll_animator/scroll_animator.dart';

class AdminNavigationScaffold extends StatelessWidget {
  const AdminNavigationScaffold(this.shell, {super.key});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    var widget = LayoutBuilder(
      builder: (context, constraints) {
        final mode = switch (constraints.maxWidth) {
          >= 1200 => PaneDisplayMode.open,
          >= 600 => PaneDisplayMode.compact,
          _ => PaneDisplayMode.minimal,
        };

        return Provider.value(
          value: mode,
          child: AdminNavigationView(child: shell),
        );
      },
    ) as Widget;

    /// If the platform is macOS, we need to account for the menu buttons
    if (Platform.isMacOS) {
      widget = IsFullScreen.builder(
        builder: (context, isFullScreen, child) {
          return Container(
            color: FluentTheme.of(context).micaBackgroundColor,
            padding: isFullScreen //
                ? EdgeInsets.zero
                : const EdgeInsets.only(top: macOSTitleBarHeight),
            child: child,
          );
        },
        child: widget,
      );
    }

    return widget;
  }
}

class AdminNavigationView extends StatefulWidget {
  const AdminNavigationView({super.key, required this.child});

  final Widget child;

  @override
  State<AdminNavigationView> createState() => _AdminNavigationViewState();
}

class _AdminNavigationViewState extends State<AdminNavigationView>
    with NavigationPanelMixin, CommonSidePanelMixin {
  late final NavRailRouteIndexMapper _routeIndexMapper;
  late final AnimatedScrollController _scrollController;
  late int _selectedIndex;

  late final List<NavigationPaneItem> _navigationItems =
      buildNavigationItems(context);
  late final List<NavigationPaneItem> _footerItems = footerItems(context);
  late final List<PaneItem> _expandedNavigationItems =
      _navigationItems.expandItems().toList();

  @override
  void initState() {
    super.initState();

    _routeIndexMapper =
        NavRailRouteIndexMapper(items: _expandedNavigationItems);
    _scrollController =
        AnimatedScrollController(animationFactory: const ChromiumEaseInOut());
    _selectedIndex = 0;
  }

  @override
  void dispose() {
    _scrollController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final paneDisplayMode = context.watch<PaneDisplayMode>();

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
      child: Provider.value(
        value: ProvidedPaneItems(_expandedNavigationItems),
        child: NavigationView(
          clipBehavior: Clip.hardEdge,

          /// The pane body builder creates the body of the window.
          ///   It is essentially the right side of the navigation view.
          paneBodyBuilder: (item, body) {
            var widget = LayoutMode.provider(child: this.widget.child);

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
            toggleable: true,
            displayMode: paneDisplayMode,
            menuButton: menuButton(),
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
            items: _navigationItems,
            footerItems: _footerItems,
          ),
        ),
      ),
    );
  }

  List<NavigationPaneItem> buildNavigationItems(BuildContext context) {
    return [
      navItem(
        icon: FluentIcons.dynamic_list,
        title: "Dashboard",
        route: AppRoutes.admin.dashboard,
      ),
      // navSearch(),
      navItem(
        icon: FluentIcons.search,
        title: "Search",
        route: AppRoutes.admin.search.products,
      ),
      PaneItemSeparator(),
      navItem(
        icon: FluentIcons.product,
        title: "Inventory",
        route: AppRoutes.admin.inventory,
        items: [
          navItem(
            icon: FluentIcons.product_list,
            title: "List of Products",
            route: AppRoutes.admin.inventory,
          ),
          navItem(
            icon: FluentIcons.product_release,
            title: "Register Product",
            route: AppRoutes.admin.createProduct,
          ),
          navItem(
            icon: FluentIcons.product_catalog,
            title: "Manage Categories",
            route: AppRoutes.admin.categories,
          ),
        ],
      ),
      navItem(
        icon: FluentIcons.text_document,
        title: 'Billing',
        route: AppRoutes.admin.billing,
        items: [
          navItem(
            icon: FluentIcons.text_document,
            title: "Invoice List",
            route: AppRoutes.admin.billing,
          ),
          navItem(
            icon: FluentIcons.text_document_edit,
            title: "Create Invoice",
            route: AppRoutes.admin.createInvoice,
          ),
        ],
      ),
      navItem(
        icon: FluentIcons.bill,
        title: 'Orders',
        route: AppRoutes.admin.order,
        items: [
          navItem(
            icon: FluentIcons.bill,
            title: 'Orders List',
            route: AppRoutes.admin.order,
          ),
          navItem(
            icon: FluentIcons.reservation_orders,
            title: 'Manage Expense Type',
            // route: AppRoutes.admin.createOrder,
          ),
        ],
      ),
      navItem(
        icon: FluentIcons.bar_chart_vertical_fill,
        title: 'Reports',
        route: AppRoutes.admin.reports,
      ),
      navItem(
        icon: FluentIcons.local_admin,
        title: 'Security',
        route: AppRoutes.admin.users,
        items: [
          navItem(
            icon: FluentIcons.contact_list,
            title: 'List of Users',
            route: AppRoutes.admin.users,
          ),
          navItem(
            icon: FluentIcons.add_friend,
            title: 'Register User',
            route: AppRoutes.admin.createUser,
          ),
          navItem(
            icon: FluentIcons.user_window,
            title: 'User Logs',
            route: AppRoutes.admin.userLogs,
          ),
        ],
      ),
      navItem(
        icon: FluentIcons.settings,
        title: 'Settings',
        items: [
          navItem(
            icon: FluentIcons.archive,
            title: 'Archived Products',
            // route: AppRoutes.admin.archivedProducts,
          ),
          navItem(
            icon: FluentIcons.save,
            title: 'System Backup',
            // route: AppRoutes.admin.systemBackup,
          ),
          navItem(
            icon: FluentIcons.help,
            title: 'Help',
            // route: AppRoutes.admin.help,
          ),
          navItem(
            icon: FluentIcons.info,
            title: 'About',
            route: AppRoutes.admin.about,
          ),
        ],
      ),
    ];
  }
}
