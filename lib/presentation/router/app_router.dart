import 'package:easthardware_pms/presentation/router/app_routes.dart';
import 'package:easthardware_pms/presentation/views/Order/order_pane_page.dart';
import 'package:easthardware_pms/presentation/views/authentication/login_page.dart';
import 'package:easthardware_pms/presentation/views/authentication/new_password_page.dart';
import 'package:easthardware_pms/presentation/views/authentication/reset_password_page.dart';
import 'package:easthardware_pms/presentation/views/billing/create_invoice_page.dart';
import 'package:easthardware_pms/presentation/views/billing/invoice_pane_page.dart';
import 'package:easthardware_pms/presentation/views/inventory/create_product_page.dart';
import 'package:easthardware_pms/presentation/views/inventory/edit_product_page.dart';
import 'package:easthardware_pms/presentation/views/inventory/inventory_pane_page.dart';
import 'package:easthardware_pms/presentation/views/inventory/manage_categories_page.dart';
import 'package:easthardware_pms/presentation/views/navigation/admin_navigation_scaffold.dart';
import 'package:easthardware_pms/presentation/views/navigation/staff_navigation_scaffold.dart';
import 'package:easthardware_pms/presentation/views/security/create_user_page.dart';
import 'package:easthardware_pms/presentation/views/security/user_log_pane.dart';
import 'package:easthardware_pms/presentation/views/security/users_pane_page.dart';
import 'package:easthardware_pms/presentation/widgets/bottom_text.dart';
import 'package:easthardware_pms/utils/typed_routes.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart' hide TypedGoRoute;

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
        TypedGoRoute(
          route: AppRoutes.resetPassword,
          builder: (context, state) => ResetPasswordPage(username: state.extra),
        ),
        GoRoute(
          path: AppRoutes.newPassword.path,
          builder: (context, state) => (NewPasswordPage(
            username: state.extra as String,
          )),
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
          initialLocation: AppRoutes.admin.dashboard.path,
          routes: [
            GoRoute(
              path: AppRoutes.admin.dashboard.path,
              builder: (context, state) => const Text("Dashboard"),
            )
          ],
        ),

        // Inventory Page Shell
        StatefulShellBranch(
          initialLocation: AppRoutes.admin.inventory.path,
          routes: [
            GoRoute(
              path: AppRoutes.admin.inventory.path,
              builder: (context, state) => (const InventoryPanePage()),
            ),
            GoRoute(
              path: AppRoutes.admin.createProduct.path,

              /// The [MaterialPage] is used for the transition animation.
              /// Should be removed if decided not to use the transition.
              builder: (context, state) => (const CreateProductPage()),
            ),
            TypedGoRoute(
              route: AppRoutes.admin.editProduct,
              builder: (context, state) => EditProductPage(product: state.extra),
            ),
            GoRoute(
              path: AppRoutes.admin.categories.path,
              builder: (context, state) => (const ManageCategoriesPage()),
            ),
          ],
        ),
        // Billing Shell
        StatefulShellBranch(
          initialLocation: AppRoutes.admin.billing.path,
          routes: [
            GoRoute(
              path: AppRoutes.admin.billing.path,
              builder: (context, state) => const InvoicePanePage(),
            ),
            GoRoute(
              path: AppRoutes.admin.createInvoice.path,
              builder: (context, state) => const CreateInvoicePage(),
            ),
          ],
        ),
        // Order Shell
        StatefulShellBranch(
          initialLocation: AppRoutes.admin.order.path,
          routes: [
            GoRoute(
              path: AppRoutes.admin.order.path,
              builder: (context, state) => const OrderPanePage(),
            ),
          ],
        ),
        StatefulShellBranch(
          initialLocation: AppRoutes.admin.users.path,
          routes: [
            GoRoute(
              path: AppRoutes.admin.users.path,
              builder: (context, state) => const UsersPanePage(),
            ),
            GoRoute(
              path: AppRoutes.admin.createUser.path,
              builder: (context, state) => const CreateUserPage(),
            ),
            GoRoute(
              path: AppRoutes.admin.userLogs.path,
              builder: (context, state) => const UserLogPane(),
            )
          ],
        )
      ],
    ),
    StatefulShellRoute(
      builder: (context, state, shell) => shell,
      navigatorContainerBuilder: (context, shell, children) {
        return BottomText(child: StaffNavigationScaffold(shell, children));
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
