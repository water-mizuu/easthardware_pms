import 'package:easthardware_pms/domain/models/product.dart';

class AppRoutes {
  static const root = AppRoute<void>('/');
  static const login = AppRoute<void>('/login');
  static const resetPassword = AppRoute<void>('/reset_password');

  // Major Page Routes
  static const admin = AppRoute<void>('/admin');
  static const staffDashboard = AppRoute<void>('/staff');
  static const inventoryPage = AppRoute<void>('/inventory');
  static const billingPage = AppRoute<void>('/billing');
  static const orderPage = AppRoute<void>('/order');
  static const reportsPage = AppRoute<void>('/reports');
  static const settingsPage = AppRoute<void>('/settings');

  // Inventory Sub Pages
  static const categoriesPage = AppRoute<void>('/categories');
  static const createProductPage = AppRoute<void>('/create/product');
  static const editProductPage = AppRoute<Product>('/edit');

  // Security Sub Pages
  static const usersPage = AppRoute<void>('/users');
  static const createUserPage = AppRoute<void>('/create/user');
  static const userLogsPage = AppRoute<void>('/logs');
}

/// A zero-cost compile-time wrapper for a string path.
///   This is used to define and use routes in a type-safe manner.
extension type const AppRoute<T>(String path) {}
