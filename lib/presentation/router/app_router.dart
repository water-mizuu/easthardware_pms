import 'package:easthardware_pms/domain/models/product.dart';
import 'package:easthardware_pms/presentation/router/app_routes.dart';
import 'package:easthardware_pms/presentation/views/authentication/login_page.dart';
import 'package:easthardware_pms/presentation/views/inventory/create_product_page.dart';
import 'package:easthardware_pms/presentation/views/inventory/edit_product_page.dart';
import 'package:easthardware_pms/presentation/views/inventory/inventory_pane_page.dart';
import 'package:easthardware_pms/presentation/views/inventory/manage_categories_page.dart';
import 'package:easthardware_pms/presentation/views/navigation/admin_navigation_scaffold.dart';
import 'package:easthardware_pms/presentation/views/security/create_user_page.dart';
import 'package:easthardware_pms/presentation/views/security/user_log_pane.dart';
import 'package:easthardware_pms/presentation/views/security/users_pane_page.dart';
import 'package:easthardware_pms/presentation/widgets/bottom_text.dart';
import 'package:easthardware_pms/presentation/widgets/title_bar.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();
final router = GoRouter(
  initialLocation: AppRoutes.login,
  navigatorKey: rootNavigatorKey,
  routes: [
    ShellRoute(
      builder: (_, __, child) => TitleBar(child: BottomText(child: child)),
      routes: [
        GoRoute(
          path: AppRoutes.login,
          builder: (context, state) => const LoginPage(),
        ),
        GoRoute(
          path: AppRoutes.resetPassword,
          builder: (context, state) => const Text("Reset Password"),
        )
      ],
    ),
    ShellRoute(
      builder: (context, state, child) => TitleBar(child: child),
      routes: [
        StatefulShellRoute(
          builder: (context, state, shell) => shell,
          navigatorContainerBuilder: (context, shell, children) =>
              BottomText(child: AdminNavigationScaffold(shell, children)),
          branches: [
            // Admin Dashboard Shell
            StatefulShellBranch(
              initialLocation: AppRoutes.admin,
              routes: [
                GoRoute(
                  path: AppRoutes.admin,
                  builder: (context, state) => const Text("Dashboard"),
                )
              ],
            ),

            // Inventory Page Shell
            StatefulShellBranch(
              initialLocation: AppRoutes.inventoryPage,
              routes: [
                GoRoute(
                  path: AppRoutes.inventoryPage,
                  builder: (context, state) => (const InventoryPanePage()),
                ),
                GoRoute(
                  path: AppRoutes.createProductPage,

                  /// The [MaterialPage] is used for the transition animation.
                  /// Should be removed if decided not to use the transition.
                  builder: (context, state) => (const CreateProductPage()),
                ),
                GoRoute(
                  path: AppRoutes.editProductPage,
                  builder: (context, state) => (EditProductPage(product: state.extra as Product)),
                ),
                GoRoute(
                  path: AppRoutes.categoriesPage,
                  builder: (context, state) => (const ManageCategoriesPage()),
                ),
              ],
            ),
            StatefulShellBranch(
              initialLocation: AppRoutes.usersPage,
              routes: [
                GoRoute(
                  path: AppRoutes.usersPage,
                  builder: (context, state) => const UsersPanePage(),
                ),
                GoRoute(
                  path: AppRoutes.createUserPage,
                  builder: (context, state) => const CreateUserPage(),
                ),
                GoRoute(
                  path: AppRoutes.userLogsPage,
                  builder: (context, state) => const UserLogPane(),
                )
              ],
            )
          ],
        ),
      ],
    ),
  ],
);
