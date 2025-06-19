import 'dart:io' show Platform;

import 'package:easthardware_pms/presentation/bloc/navigation/navigation_cubit.dart';
import 'package:easthardware_pms/presentation/router/app_routes.dart';
import 'package:easthardware_pms/presentation/views/navigation/common_side_panel_mixin.dart';
import 'package:easthardware_pms/presentation/widgets/brand/navrail_header.dart';
import 'package:easthardware_pms/presentation/widgets/helper/nav_rail_route_index_mapper.dart';
import 'package:easthardware_pms/presentation/widgets/is_full_screen_provider.dart';
import 'package:easthardware_pms/presentation/widgets/layout_mode_provider.dart';
import 'package:easthardware_pms/presentation/widgets/title_bar.dart';
import 'package:easthardware_pms/utils/typed_routes.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:scroll_animator/scroll_animator.dart';

class StaffNavigationScaffold extends StatelessWidget {
  const StaffNavigationScaffold(this.shell, {super.key});

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
          child: StaffNavigationView(child: shell),
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

class StaffNavigationView extends StatefulWidget {
  const StaffNavigationView({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  State<StaffNavigationView> createState() => _StaffNavigationViewState();
}

class _StaffNavigationViewState extends State<StaffNavigationView>
    with NavigationPanelMixin, CommonSidePanelMixin {
  late final NavRailRouteIndexMapper _routeIndexMapper;
  late final AnimatedScrollController _scrollController;
  late int _selectedIndex;

  late final List<NavigationPaneItem> _navigationItems = buildNavigationItems(context);
  late final List<NavigationPaneItem> _footerItems = footerItems(context);
  late final List<PaneItem> _expandedNavigationItems = _navigationItems.expandItems().toList();

  @override
  void initState() {
    super.initState();

    _routeIndexMapper = NavRailRouteIndexMapper(items: _expandedNavigationItems);
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
    final paneDisplayMode = context.watch<PaneDisplayMode>();

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
            toggleable: false,
            displayMode: paneDisplayMode,
            menuButton: menuButton(),
            onItemPressed: (index) {
              /// Redirects such as this should be specified in the
              ///   [_navigationItems] list.
              final probablyRoute = _routeIndexMapper.getRouteFromIndex(index);
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
        route: AppRoutes.staff.dashboard,
      ),
      navItem(
        icon: FluentIcons.search,
        title: "Search",
        route: AppRoutes.staff.search.products,
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
            route: AppRoutes.staff.billing,
          ),
          navItem(
            icon: FluentIcons.text_document_edit,
            title: "Pay Invoice",
            route: AppRoutes.staff.payInvoice,
          ),
        ],
      ),
      navItem(
        icon: FluentIcons.bar_chart_vertical_fill,
        title: 'Reports',
        // route: AppRoutes.reportsPage,
      ),
      navItem(
        icon: FluentIcons.settings,
        title: 'Settings',
        items: [
          navItem(
            icon: FluentIcons.help,
            title: 'Help',
            route: AppRoutes.staff.help,
          ),
          navItem(
            icon: FluentIcons.info,
            title: 'About',
            route: AppRoutes.staff.about,
          ),
        ],
      ),
    ];
  }
}
