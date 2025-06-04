import 'package:easthardware_pms/domain/models/product.dart';

class AppRoutes {
  static const root = AppRoute<Null>('/');
  static const login = AppRoute<Null>('/login');
  static const resetPassword =
      AppRoute<String>('/reset_password_authentication');
  static const newPassword = AppRoute<String>('/new_password');

  // Major Page Routes
  static const admin = AppRoute<Null>('/admin');
  static const staffDashboard = AppRoute<Null>('/staff');
  static const inventoryPage = AppRoute<Null>('/inventory');
  static const billingPage = AppRoute<Null>('/billing');
  static const orderPage = AppRoute<Null>('/order');
  static const reportsPage = AppRoute<Null>('/reports');
  static const settingsPage = AppRoute<Null>('/settings');

  // Inventory Sub Pages
  static const categoriesPage = AppRoute<Null>('/categories');
  static const createProductPage = AppRoute<Null>('/create/product');
  static const editProductPage = AppRoute<Product>('/edit');

  // Billing SubPages
  static const createInvoicePage = AppRoute<Null>('/create/invoice');
  static const String payInvoicePage = 'pay/invoice';

  // Security Sub Pages
  static const usersPage = AppRoute<Null>('/users');
  static const createUserPage = AppRoute<Null>('/create/user');
  static const userLogsPage = AppRoute<Null>('/logs');
}

/// A zero-cost compile-time wrapper for a string path.
///   This is used to define and use routes in a type-safe manner.
extension type const AppRoute<T>(String path) {}
