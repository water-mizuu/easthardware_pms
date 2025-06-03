import 'package:easthardware_pms/presentation/router/app_routes.dart';
import 'package:easthardware_pms/presentation/views/authentication/login_page.dart';
import 'package:easthardware_pms/presentation/views/authentication/new_password_page.dart';
import 'package:easthardware_pms/presentation/views/authentication/reset_password_page.dart';
import 'package:easthardware_pms/presentation/views/billing/create_invoice_page.dart';
import 'package:easthardware_pms/presentation/views/billing/invoice_pane_page.dart';
import 'package:easthardware_pms/presentation/views/inventory/inventory_pane_page.dart';
import 'package:easthardware_pms/presentation/views/navigation/admin_navigation_scaffold.dart';
import 'package:easthardware_pms/presentation/widgets/bottom_text.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

const initialLocation = AppRoutes.login;

final rootWidgetKey = GlobalKey<NavigatorState>();
final router = GoRouter(
  initialLocation: initialLocation as String,
  navigatorKey: rootWidgetKey,
  routes: [
    ShellRoute(
      builder: (_, __, child) => BottomText(child: child),
      routes: [
        GoRoute(
          path: AppRoutes.login.path,
          builder: (context, state) => const LoginPage(),
        ),
        GoRoute(
          path: AppRoutes.resetPassword.path,
          builder: (context, state) => ResetPasswordPage(username: state.extra as String),
        ),
        GoRoute(
          path: AppRoutes.newPassword.path,
          builder: (context, state) => (const NewPasswordPage()),
        )
      ],
    ),
    StatefulShellRoute(
      builder: (context, state, shell) => shell,
      navigatorContainerBuilder: (context, shell, children) {
        return BottomText(child: AdminNavigationScaffold(shell, children));
      },
      branches: [
        // Admin Dashboard Shell
        StatefulShellBranch(
          initialLocation: AppRoutes.staff.dashboard.path,
          routes: [
            GoRoute(
              path: AppRoutes.staff.dashboard.path,
              builder: (context, state) => const Text("Dashboard"),
            )
          ],
        ),

        // Inventory Page Shell
        StatefulShellBranch(
          initialLocation: AppRoutes.staff.inventory.path,
          routes: [
            GoRoute(
              path: AppRoutes.staff.inventory.path,
              builder: (context, state) => (const InventoryPanePage()),
            ),
          ],
        ),

        // Invoice Shell
        StatefulShellBranch(
          initialLocation: AppRoutes.staff.createInvoice.path,
          routes: [
            GoRoute(
              path: AppRoutes.staff.createInvoice.path,
              builder: (context, state) => const CreateInvoicePage(),
            ),
            GoRoute(
              path: AppRoutes.staff.payInvoice.path,
              builder: (context, state) => const InvoicePanePage(),
            ),
          ],
        ),

        StatefulShellBranch(
          initialLocation: AppRoutes.staff.help.path,
          routes: [
            GoRoute(
              path: AppRoutes.staff.help.path,
              builder: (context, state) => const Text("Help Page"),
            ),
          ],
        ),

        StatefulShellBranch(
          initialLocation: AppRoutes.staff.about.path,
          routes: [
            GoRoute(
              path: AppRoutes.staff.about.path,
              builder: (context, state) => const Text("About Page"),
            ),
          ],
        ),
      ],
    ),
  ],
);
