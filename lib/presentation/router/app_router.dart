import 'package:easthardware_pms/domain/models/product.dart';
import 'package:easthardware_pms/presentation/router/app_routes.dart';
import 'package:easthardware_pms/presentation/views/authentication/login_page.dart';
import 'package:easthardware_pms/presentation/views/billing/create_invoice_page.dart';
import 'package:easthardware_pms/presentation/views/billing/invoice_pane_page.dart';
import 'package:easthardware_pms/presentation/views/authentication/new_password_page.dart';
import 'package:easthardware_pms/presentation/views/authentication/reset_password_page.dart';
import 'package:easthardware_pms/presentation/views/inventory/create_product_page.dart';
import 'package:easthardware_pms/presentation/views/inventory/edit_product_page.dart';
import 'package:easthardware_pms/presentation/views/inventory/inventory_pane_page.dart';
import 'package:easthardware_pms/presentation/views/inventory/manage_categories_page.dart';
import 'package:easthardware_pms/presentation/views/navigation/admin_navigation_scaffold.dart';
import 'package:easthardware_pms/presentation/views/security/create_user_page.dart';
import 'package:easthardware_pms/presentation/views/security/user_log_pane.dart';
import 'package:easthardware_pms/presentation/views/security/users_pane_page.dart';
import 'package:easthardware_pms/presentation/widgets/bottom_text.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

const initialLocation = AppRoutes.login;

final rootWidgetKey = GlobalKey<NavigatorState>();
final router =
    GoRouter(initialLocation: initialLocation as String, navigatorKey: rootWidgetKey, routes: [
  ShellRoute(
    builder: (_, __, child) => BottomText(child: child),
    routes: [
      GoRoute(
        path: AppRoutes.login.path,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: AppRoutes.resetPassword.path,
        builder: (context, state) => (const ResetPasswordPage()),
      ),
      GoRoute(
        path: AppRoutes.newPassword.path,
        builder: (context, state) => (const NewPasswordPage()),
      )
    ],
  ),
  StatefulShellRoute(
      builder: (context, state, shell) => shell,
      navigatorContainerBuilder: (context, shell, children) =>
          BottomText(child: AdminNavigationScaffold(shell, children)),
      branches: [
        // Admin Dashboard Shell
        StatefulShellBranch(
          initialLocation: AppRoutes.admin.path,
          routes: [
            GoRoute(
              path: AppRoutes.admin.path,
              builder: (context, state) => const Text("Dashboard"),
            )
          ],
        ),

        // Inventory Page Shell
        StatefulShellBranch(
          initialLocation: AppRoutes.inventoryPage.path,
          routes: [
            GoRoute(
              path: AppRoutes.inventoryPage.path,
              builder: (context, state) => (const InventoryPanePage()),
            ),
            GoRoute(
              path: AppRoutes.createProductPage.path,

              /// The [MaterialPage] is used for the transition animation.
              /// Should be removed if decided not to use the transition.
              builder: (context, state) => (const CreateProductPage()),
            ),
            GoRoute(
              path: AppRoutes.editProductPage.path,
              builder: (context, state) => (EditProductPage(product: state.extra as Product)),
            ),
            GoRoute(
              path: AppRoutes.categoriesPage.path,
              builder: (context, state) => (const ManageCategoriesPage()),
            ),
          ],
        ),
        // Billing Shell
        StatefulShellBranch(
          initialLocation: AppRoutes.billingPage.path,
          routes: [
            GoRoute(
                path: AppRoutes.billingPage.path,
                builder: (context, state) => const InvoicePanePage()),
            GoRoute(
              path: AppRoutes.createInvoicePage.path,
              builder: (context, state) => const CreateInvoicePage(),
            ),
          ],
        ),
        StatefulShellBranch(
          initialLocation: AppRoutes.usersPage.path,
          routes: [
            GoRoute(
              path: AppRoutes.usersPage.path,
              builder: (context, state) => const UsersPanePage(),
            ),
            GoRoute(
              path: AppRoutes.createUserPage.path,
              builder: (context, state) => const CreateUserPage(),
            ),
            GoRoute(
              path: AppRoutes.userLogsPage.path,
              builder: (context, state) => const UserLogPane(),
            )
          ],
        )
      ])
]);
