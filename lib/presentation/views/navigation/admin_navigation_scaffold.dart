import 'dart:io' show Platform;

import 'package:easthardware_pms/presentation/bloc/navigation/navigation_bloc.dart';
import 'package:easthardware_pms/presentation/widgets/brand/navrail_header.dart';
import 'package:easthardware_pms/presentation/widgets/helper/route_index_mapper.dart';
import 'package:easthardware_pms/presentation/widgets/title_bar.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class AdminNavigationScaffold extends StatelessWidget {
  const AdminNavigationScaffold(this.shell, this.children, {super.key});

  final StatefulNavigationShell shell;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<NavigationBloc, NavigationState>(
      listener: (context, state) {
        final route = RouteIndexMapper.getRouteFromIndex(state);
        if (route != null && state.selectedIndex != shell.currentIndex) {
          context.push(route);
        }
      },
      builder: (context, state) {
        var widget = NavigationView(
          clipBehavior: Clip.hardEdge,
          paneBodyBuilder: (item, body) {
            final padding = TitleBar.of(context) && (!Platform.isMacOS) //
                ? EdgeInsets.only(top: windowsTitleBarHeight)
                : EdgeInsets.zero;

            return Padding(padding: padding, child: children[shell.currentIndex]);
          },
          pane: NavigationPane(
            header: const LogoRow(),
            selected: state.selectedIndex,
            displayMode: PaneDisplayMode.auto,
            onItemPressed: (index) {
              if ([1, 12].contains(index)) {
                index++; // Example: skip separator, handle expander index
              }
              if (index == 16) return; // Example: specific index to ignore
              context.read<NavigationBloc>().add(NavigationIndexChanged(index: index));
            },
            items: [
              _createNavItem(
                icon: FluentIcons.dynamic_list,
                title: "Dashboard",
              ),
              PaneItemSeparator(),
              _createNavItem(
                icon: FluentIcons.product,
                title: "Inventory",
                items: _getInventorySubItems(),
              ),
              _createNavItem(
                icon: FluentIcons.text_document,
                title: 'Billing',
                items: _getBillingSubItems(),
              ),
              _createNavItem(
                icon: FluentIcons.bill,
                title: 'Orders',
                items: _getOrderSubItems(),
              ),
              _createNavItem(
                icon: FluentIcons.bar_chart_vertical_fill,
                title: 'Reports',
              ),
              _createNavItem(
                icon: FluentIcons.local_admin,
                title: 'Security',
                items: _getSecuritySubItems(),
              )
              //
            ],
          ),
        ) as Widget;

        /// If the platform is macOS, we need to account for the title bar on the left.
        if (Platform.isMacOS) {
          widget = Container(
            color: FluentTheme.of(context).micaBackgroundColor,
            padding: EdgeInsets.only(top: macOSTitleBarHeight),
            child: widget,
          );
        }

        return widget;
      },
    );
  }

  NavigationPaneItem _createNavItem({
    required IconData icon,
    required String title,
    List<NavigationPaneItem>? items,
    VoidCallback? onTap,
    Widget body = const SizedBox(),
  }) {
    if (items != null && items.isNotEmpty) {
      return PaneItemExpander(
        icon: Icon(icon),
        title: Text(title),
        items: items,
        body: body,
      );
    } else {
      return PaneItem(
        icon: Icon(icon),
        title: Text(title),
        body: body,
        onTap: onTap,
      );
    }
  }

  List<NavigationPaneItem> _getInventorySubItems() {
    return [
      _createNavItem(icon: FluentIcons.product_list, title: "List of Products"),
      _createNavItem(icon: FluentIcons.product_release, title: "Register Product"),
      _createNavItem(icon: FluentIcons.product_catalog, title: "Manage Categories"),
    ];
  }

  List<NavigationPaneItem> _getBillingSubItems() {
    return [
      _createNavItem(icon: FluentIcons.text_document, title: "Invoice List"),
      _createNavItem(icon: FluentIcons.text_document_edit, title: "Payments"),
    ];
  }

  List<NavigationPaneItem> _getOrderSubItems() {
    return [
      _createNavItem(icon: FluentIcons.bill, title: 'Orders List'),
      _createNavItem(icon: FluentIcons.reservation_orders, title: 'Manage Expense Type'),
    ];
  }

  List<NavigationPaneItem> _getSecuritySubItems() {
    return [
      _createNavItem(icon: FluentIcons.contact_list, title: 'List of Users'),
      _createNavItem(icon: FluentIcons.add_friend, title: 'Register User'),
      _createNavItem(icon: FluentIcons.user_window, title: 'User Logs'),
      _createNavItem(
        icon: FluentIcons.leave,
        title: 'Log Out',
        onTap: () {
          if (kDebugMode) {
            print('Log out');
          }
        },
      ),
    ];
  }
}
