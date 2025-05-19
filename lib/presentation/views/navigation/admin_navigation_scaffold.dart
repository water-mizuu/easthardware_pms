import 'package:easthardware_pms/presentation/bloc/navigation/navigation_bloc.dart';
import 'package:easthardware_pms/presentation/widgets/brand/navrail_header.dart';
import 'package:easthardware_pms/presentation/widgets/helper/route_index_mapper.dart';
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
        return Stack(
          children: [
            NavigationView(
              paneBodyBuilder: (item, body) {
                return children[shell.currentIndex];
              },
              pane: NavigationPane(
                header: const LogoRow(),
                selected: state.selectedIndex,
                displayMode: PaneDisplayMode.auto,
                onItemPressed: (index) {
                  if ([1, 12].contains(index)) index++;
                  if (kDebugMode) {
                    print((index));
                  }
                  if (index == 16) return;
                  context.read<NavigationBloc>().add(NavigationIndexChanged(index: index));
                },
                items: [
                  PaneItem(
                    icon: const Icon(FluentIcons.dynamic_list),
                    title: const Text("Dashboard"),
                    body: const SizedBox(),
                  ),
                  PaneItemSeparator(),
                  PaneItemExpander(
                    icon: const Icon(FluentIcons.product),
                    title: const Text("Inventory"),
                    body: const SizedBox(),
                    items: _inventorySubItems,
                  ),
                  PaneItemExpander(
                    title: const Text('Billing'),
                    icon: const Icon(FluentIcons.text_document),
                    items: _billingSubItems,
                    body: const SizedBox(),
                  ),
                  PaneItemExpander(
                    title: const Text('Orders'),
                    icon: const Icon(FluentIcons.bill),
                    items: _orderSubItems,
                    body: const SizedBox(),
                  ),
                  PaneItem(
                    icon: const Icon(FluentIcons.bar_chart_vertical_fill),
                    title: const Text('Reports'),
                    body: const SizedBox(),
                  ),
                  PaneItemExpander(
                    icon: const Icon(FluentIcons.local_admin),
                    title: const Text('Security'),
                    items: _securitySubItems,
                    body: const SizedBox(),
                  )
                  //
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

List<NavigationPaneItem> _inventorySubItems = [
  PaneItem(
    icon: const Icon(FluentIcons.product_list),
    title: const Text("List of Products"),
    body: const SizedBox(),
  ),
  PaneItem(
    icon: const Icon(FluentIcons.product_release),
    title: const Text("Register Product"),
    body: const SizedBox(),
  ),
  PaneItem(
    icon: const Icon(FluentIcons.product_catalog),
    title: const Text("Manage Categories"),
    body: const SizedBox(),
  ),
];

List<NavigationPaneItem> _billingSubItems = [
  PaneItem(
    icon: const Icon(FluentIcons.text_document),
    title: const Text("Invoice List"),
    body: const SizedBox(),
  ),
  PaneItem(
    icon: const Icon(FluentIcons.text_document_edit),
    title: const Text("Payments"),
    body: const SizedBox(),
  ),
];

List<NavigationPaneItem> _orderSubItems = [
  PaneItem(
    icon: const Icon(FluentIcons.bill),
    title: const Text('Orders List'),
    body: const SizedBox(),
  ),
  PaneItem(
    icon: const Icon(FluentIcons.reservation_orders),
    title: const Text('Manage Expense Type'),
    body: const SizedBox(),
  ),
];

List<NavigationPaneItem> _securitySubItems = [
  PaneItem(
    icon: const Icon(FluentIcons.contact_list),
    title: const Text('List of Users'),
    body: const SizedBox(),
  ),
  PaneItem(
    icon: const Icon(FluentIcons.add_friend),
    title: const Text('Register User'),
    body: const SizedBox(),
  ),
  PaneItem(
    icon: const Icon(FluentIcons.user_window),
    title: const Text('User Logs'),
    body: const SizedBox(),
  ),
  PaneItem(
    icon: const Icon(FluentIcons.leave),
    title: const Text('Log Out'),
    body: const SizedBox(),
    onTap: () {
      print('Log out');
    },
  ),
];
