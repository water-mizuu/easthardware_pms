import 'package:easthardware_pms/presentation/router/app_routes.dart';
import 'package:easthardware_pms/presentation/views/Order/create_expense_order_page.dart';
import 'package:easthardware_pms/presentation/views/Order/create_restock_order_page.dart';
import 'package:easthardware_pms/presentation/views/Order/order_pane_page.dart';
import 'package:easthardware_pms/presentation/views/Reports/report_list_pane.dart';
import 'package:easthardware_pms/presentation/views/authentication/login_page.dart';
import 'package:easthardware_pms/presentation/views/authentication/new_password_page.dart';
import 'package:easthardware_pms/presentation/views/authentication/reset_password_page.dart';
import 'package:easthardware_pms/presentation/views/billing/create_invoice_page.dart';
import 'package:easthardware_pms/presentation/views/billing/invoice_pane_page.dart';
import 'package:easthardware_pms/presentation/views/dashboard/admin_dashboard_pane_page.dart';
import 'package:easthardware_pms/presentation/views/dashboard/staff_dashboard_pane_page.dart';
import 'package:easthardware_pms/presentation/views/inventory/create_product_page.dart';
import 'package:easthardware_pms/presentation/views/inventory/edit_product_page.dart';
import 'package:easthardware_pms/presentation/views/inventory/inventory_pane_page.dart';
import 'package:easthardware_pms/presentation/views/inventory/manage_categories_page.dart';
import 'package:easthardware_pms/presentation/views/navigation/admin_navigation_scaffold.dart';
import 'package:easthardware_pms/presentation/views/navigation/staff_navigation_scaffold.dart';
import 'package:easthardware_pms/presentation/views/payment/create_payment_page.dart';
import 'package:easthardware_pms/presentation/views/payment/payments_pane_page.dart';
import 'package:easthardware_pms/presentation/views/search/search_page.dart';
import 'package:easthardware_pms/presentation/views/search/search_top_bar.dart';
import 'package:easthardware_pms/presentation/views/security/create_user_page.dart';
import 'package:easthardware_pms/presentation/views/security/user_log_pane.dart';
import 'package:easthardware_pms/presentation/views/security/users_pane_page.dart';
import 'package:easthardware_pms/presentation/views/settings/about_page.dart';
import 'package:easthardware_pms/presentation/widgets/bottom_text.dart';
import 'package:easthardware_pms/utils/boxed.dart';
import 'package:easthardware_pms/utils/typed_routes.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart' hide TypedGoRoute;

final keys = (searchKey: GlobalKey<NavigatorState>(),);

const initialLocation = AppRoutes.login;

class AggregatedObserver implements NavigatorObserver {
  @override
  void didPop(Route route, Route? previousRoute) {
    if (route.settings.name case final path?) {
      _didChangeRoute(path);
    }
  }

  @override
  void didPush(Route route, Route? previousRoute) {
    if (route.settings.name case final path?) {
      _didChangeRoute(path);
    }
  }

  @override
  void didRemove(Route route, Route? previousRoute) {
    if (route.settings.name case final path?) {
      _didChangeRoute(path);
    }
  }

  @override
  void didReplace({Route? newRoute, Route? oldRoute}) {
    if (newRoute?.settings.name case final path?) {
      _didChangeRoute(path);
    }
  }

  @override
  void didStartUserGesture(Route route, Route? previousRoute) {
    if (route.settings.name case final path?) {
      _didChangeRoute(path);
    }
  }

  @override
  void didStopUserGesture() {}

  @override
  NavigatorState? get navigator => null;

  void _didChangeRoute(String path) {
    printBoxed("New path: $path", "March");
  }
}

class MyObserver extends NavigatorObserver {
  MyObserver(this._aggregated);

  final AggregatedObserver _aggregated;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _aggregated.didPush(route, previousRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _aggregated.didPop(route, previousRoute);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _aggregated.didRemove(route, previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    _aggregated.didReplace(newRoute: newRoute, oldRoute: oldRoute);
  }

  @override
  void didStartUserGesture(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _aggregated.didStartUserGesture(route, previousRoute);
  }

  @override
  void didStopUserGesture() {
    _aggregated.didStopUserGesture();
  }
}

final _observer = AggregatedObserver();

/// This is the global key for the root navigator. This should be used for modals.
final rootWidgetKey = GlobalKey<NavigatorState>(debugLabel: "Complain the money's hard");

/// This is the global key for the inner navigator, containing the overlay.
///   This should be used for overlay calls.
final overlayWidgetKey = GlobalKey<NavigatorState>(debugLabel: "bailey");
final router = GoRouter(
  initialLocation: initialLocation as String,
  navigatorKey: rootWidgetKey,
  observers: [MyObserver(_observer)],
  routes: [
    ShellRoute(
      navigatorKey: overlayWidgetKey,
      observers: [MyObserver(_observer)],
      builder: (_, __, child) => Overlay.wrap(child: child),
      routes: [
        ShellRoute(
          observers: [MyObserver(_observer)],
          builder: (_, __, child) => BottomText(child: child),
          routes: [
            TypedGoRoute(
              route: AppRoutes.login,
              builder: (context, state) => const LoginPage(),
            ),
            TypedGoRoute(
              route: AppRoutes.resetPassword,
              builder: (context, state) => ResetPasswordPage(username: state.extra),
            ),
            TypedGoRoute(
              route: AppRoutes.newPassword,
              builder: (context, state) => NewPasswordPage(username: state.extra),
            )
          ],
        ),
        StatefulShellRoute.indexedStack(
          builder: (context, state, shell) => BottomText(child: AdminNavigationScaffold(shell)),
          branches: [
            // Admin Dashboard Shell
            StatefulShellBranch(
              observers: [MyObserver(_observer)],
              initialLocation: AppRoutes.admin.dashboard.path,
              routes: [
                TypedGoRoute(
                  route: AppRoutes.admin.dashboard,
                  builder: (context, state) => const AdminDashboardPanePage(),
                )
              ],
            ),

            // Search Page Shell
            StatefulShellBranch(
              observers: [MyObserver(_observer)],
              navigatorKey: keys.searchKey,
              initialLocation: AppRoutes.admin.search.products.path,
              routes: [
                StatefulShellRoute.indexedStack(
                  builder: (context, state, shell) => SearchPage(shell),
                  branches: [
                    StatefulShellBranch(
                      initialLocation: AppRoutes.admin.search.products.path,
                      routes: [
                        TypedGoRoute(
                          route: AppRoutes.admin.search.products,
                          builder: (context, state) => ProductsBody(),
                        ),
                      ],
                    ),
                    StatefulShellBranch(
                      initialLocation: AppRoutes.admin.search.invoices.path,
                      routes: [
                        TypedGoRoute(
                          route: AppRoutes.admin.search.invoices,
                          builder: (context, state) => InvoicesBody(),
                        ),
                      ],
                    ),
                    StatefulShellBranch(
                      initialLocation: AppRoutes.admin.search.orders.path,
                      routes: [
                        TypedGoRoute(
                          route: AppRoutes.admin.search.orders,
                          builder: (context, state) => OrdersBody(),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),

            // Inventory Page Shell
            StatefulShellBranch(
              observers: [MyObserver(_observer)],
              initialLocation: AppRoutes.admin.inventory.path,
              routes: [
                TypedGoRoute(
                  route: AppRoutes.admin.inventory,
                  builder: (context, state) => (const InventoryPanePage()),
                ),
                TypedGoRoute(
                  route: AppRoutes.admin.createProduct,

                  /// The [MaterialPage] is used for the transition animation.
                  /// Should be removed if decided not to use the transition.
                  builder: (context, state) => (const CreateProductPage()),
                ),
                TypedGoRoute(
                  route: AppRoutes.admin.editProduct,
                  builder: (context, state) => EditProductPage(product: state.extra),
                ),
                TypedGoRoute(
                  route: AppRoutes.admin.categories,
                  builder: (context, state) => (const ManageCategoriesPage()),
                ),
              ],
            ),
            // Billing Shell
            StatefulShellBranch(
              observers: [MyObserver(_observer)],
              initialLocation: AppRoutes.admin.billing.path,
              routes: [
                TypedGoRoute(
                  route: AppRoutes.admin.billing,
                  builder: (context, state) => const InvoicePanePage(),
                ),
                TypedGoRoute(
                  route: AppRoutes.admin.createInvoice,
                  builder: (context, state) => const CreateInvoicePage(),
                ),
              ],
            ),
            StatefulShellBranch(
              observers: [MyObserver(_observer)],
              initialLocation: AppRoutes.admin.payment.path,
              routes: [
                TypedGoRoute(
                  route: AppRoutes.admin.payment,
                  builder: (context, state) => const PaymentsPanePage(),
                ),
                TypedGoRoute(
                  route: AppRoutes.admin.createPayment,
                  builder: (context, state) => CreatePaymentPage(invoice: state.extra),
                ),
              ],
            ),
            // Order Shell
            StatefulShellBranch(
              observers: [MyObserver(_observer)],
              initialLocation: AppRoutes.admin.order.path,
              routes: [
                TypedGoRoute(
                  route: AppRoutes.admin.order,
                  builder: (context, state) => const OrderPanePage(),
                ),
                TypedGoRoute(
                  route: AppRoutes.admin.createRestockOrder,
                  builder: (context, state) => const CreateRestockOrderPage(),
                ),
                TypedGoRoute(
                  route: AppRoutes.admin.createExpenseOrder,
                  builder: (context, state) => const CreateExpenseOrderPage(),
                ),
              ],
            ),

            // Reports Shell
            StatefulShellBranch(
              observers: [MyObserver(_observer)],
              //initialLocation: AppRoutes.admin.users.path,
              routes: [
                TypedGoRoute(
                  route: AppRoutes.admin.reports,
                  builder: (context, state) => const ReportListPane(),
                )
              ],
            ),

            // Security Shell
            StatefulShellBranch(
              observers: [MyObserver(_observer)],
              initialLocation: AppRoutes.admin.users.path,
              routes: [
                TypedGoRoute(
                  route: AppRoutes.admin.users,
                  builder: (context, state) => const UsersPanePage(),
                ),
                TypedGoRoute(
                  route: AppRoutes.admin.createUser,
                  builder: (context, state) => const CreateUserPage(),
                ),
                TypedGoRoute(
                  route: AppRoutes.admin.userLogs,
                  builder: (context, state) => const UserLogPane(),
                )
              ],
            ),
            // Settings Shell
            StatefulShellBranch(
              observers: [MyObserver(_observer)],
              //initialLocation: AppRoutes.admin.users.path,
              routes: [
                TypedGoRoute(
                  route: AppRoutes.admin.about,
                  builder: (context, state) => const AboutPanePage(),
                )
              ],
            ),
          ],
        ),
        StatefulShellRoute.indexedStack(
          builder: (context, state, shell) => BottomText(child: StaffNavigationScaffold(shell)),
          branches: [
            // Staff Dashboard Shell
            StatefulShellBranch(
              observers: [MyObserver(_observer)],
              initialLocation: AppRoutes.staff.dashboard.path,
              routes: [
                GoRoute(
                  path: AppRoutes.staff.dashboard.path,
                  builder: (context, state) => const StaffDashboardPanePage(),
                )
              ],
            ),

            // Search Page Shell
            StatefulShellBranch(
              observers: [MyObserver(_observer)],
              navigatorKey: keys.searchKey,
              initialLocation: AppRoutes.staff.search.products.path,
              routes: [
                StatefulShellRoute.indexedStack(
                  builder: (context, state, shell) => SearchPage(shell),
                  branches: [
                    StatefulShellBranch(
                      initialLocation: AppRoutes.staff.search.products.path,
                      routes: [
                        TypedGoRoute(
                          route: AppRoutes.staff.search.products,
                          builder: (context, state) => ProductsBody(),
                        ),
                      ],
                    ),
                    StatefulShellBranch(
                      initialLocation: AppRoutes.staff.search.invoices.path,
                      routes: [
                        TypedGoRoute(
                          route: AppRoutes.staff.search.invoices,
                          builder: (context, state) => InvoicesBody(),
                        ),
                      ],
                    ),
                    StatefulShellBranch(
                      initialLocation: AppRoutes.staff.search.orders.path,
                      routes: [
                        TypedGoRoute(
                          route: AppRoutes.staff.search.orders,
                          builder: (context, state) => OrdersBody(),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),

            // Inventory Page Shell
            StatefulShellBranch(
              observers: [MyObserver(_observer)],
              initialLocation: AppRoutes.staff.inventory.path,
              routes: [
                TypedGoRoute(
                  route: AppRoutes.staff.inventory,
                  builder: (context, state) => (const InventoryPanePage()),
                ),
              ],
            ),

            // Invoice Shell
            StatefulShellBranch(
              observers: [MyObserver(_observer)],
              initialLocation: AppRoutes.staff.createInvoice.path,
              routes: [
                TypedGoRoute(
                  route: AppRoutes.staff.billing,
                  builder: (context, state) => const InvoicePanePage(),
                ),
                TypedGoRoute(
                  route: AppRoutes.staff.createInvoice,
                  builder: (context, state) => const CreateInvoicePage(),
                ),
                TypedGoRoute(
                  route: AppRoutes.staff.payInvoice,
                  builder: (context, state) => const InvoicePanePage(),
                ),
                TypedGoRoute(
                  route: AppRoutes.staff.billing,
                  builder: (context, state) => const InvoicePanePage(),
                ),
              ],
            ),

            StatefulShellBranch(
              observers: [MyObserver(_observer)],
              // initialLocation: AppRoutes.staff.createInvoice.path,
              routes: [
                TypedGoRoute(
                  route: AppRoutes.staff.order,
                  builder: (context, state) => const OrderPanePage(),
                ),
                TypedGoRoute(
                  route: AppRoutes.staff.payInvoice,
                  builder: (context, state) => const InvoicePanePage(),
                ),
              ],
            ),

            StatefulShellBranch(
              observers: [MyObserver(_observer)],
              initialLocation: AppRoutes.staff.about.path,
              routes: [
                TypedGoRoute(
                  route: AppRoutes.staff.about,
                  builder: (context, state) => const AboutPanePage(),
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  ],
);
