import 'dart:io' show Platform;

import 'package:easthardware_pms/presentation/bloc/navigation/navigation_cubit.dart';
import 'package:easthardware_pms/presentation/router/app_routes.dart';
import 'package:easthardware_pms/presentation/views/navigation/common_side_panel_mixin.dart';
import 'package:easthardware_pms/presentation/widgets/brand/navrail_header.dart';
import 'package:easthardware_pms/presentation/widgets/helper/nav_rail_route_index_mapper.dart';
import 'package:easthardware_pms/presentation/widgets/layout_mode_provider.dart';
import 'package:easthardware_pms/presentation/widgets/title_bar.dart';
import 'package:easthardware_pms/utils/typed_routes.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:scroll_animator/scroll_animator.dart';

class StaffNavigationScaffold extends StatelessWidget {
  const StaffNavigationScaffold(this.shell, this.children, {super.key});

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

class _AdminNavigationViewState extends State<AdminNavigationView> with CommonSidePanelMixin {
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
        BlocListener<NavigationCubit, NavigationState>(
          listener: (context, state) {
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
            /// Redirects such as this should be specified in the
            ///   [_navigationItems] list.
            final probablyRoute = _routeIndexMapper.getRouteFromIndex(index);
            if (probablyRoute case final AppRoute<Null> route) {
              context.navigate(route);
              return;
            }
          },
          items: _navigationItems(context),
          footerItems: footerItems(context),
        ),
      ),
    );
  }

  List<NavigationPaneItem> _navigationItems(BuildContext context) {
    return [
      navItem(
        icon: FluentIcons.dynamic_list,
        title: "Dashboard",
        route: AppRoutes.staff.dashboard,
      ),
      PaneItemSeparator(),
      navItem(
        icon: FluentIcons.product,
        title: "Inventory",
        route: AppRoutes.staff.inventory,
      ),
      navItem(
        icon: FluentIcons.text_document,
        title: 'Billing',
        // route: AppRoutes.billingPage,
        items: [
          navItem(
            icon: FluentIcons.text_document,
            title: "Invoice List",
            route: AppRoutes.staff.createInvoice,
          ),
          navItem(
            icon: FluentIcons.text_document_edit,
            title: "Pay Invoice",
            route: AppRoutes.staff.payInvoice,
          ),
        ],
      ),
      navItem(
        icon: FluentIcons.bill,
        title: 'Orders',
        // route: AppRoutes.orderPage,
        items: [
          navItem(
            icon: FluentIcons.bill,
            title: 'Orders List',
            // route: AppRoutes.orderPage,
          ),
          navItem(
            icon: FluentIcons.reservation_orders,
            title: 'Manage Expense Type',
            // route: AppRoutes.orderPage,
          ),
        ],
      ),
      navItem(
        icon: FluentIcons.bar_chart_vertical_fill,
        title: 'Reports',
        // route: AppRoutes.reportsPage,
      ),
    ];
  }
}
