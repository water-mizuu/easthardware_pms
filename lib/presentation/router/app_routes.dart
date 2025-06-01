class AppRoutes {
  static const AppRoute root = AppRoute('/');
  static const AppRoute login = AppRoute('/login');
  static const AppRoute resetPassword = AppRoute('/reset_password');

  // Major Page Routes
  static const AppRoute admin = AppRoute('/admin');
  static const AppRoute staffDashboard = AppRoute('/staff');
  static const AppRoute inventoryPage = AppRoute('/inventory');
  static const AppRoute billingPage = AppRoute('/billing');
  static const AppRoute orderPage = AppRoute('/order');
  static const AppRoute reportsPage = AppRoute('/reports');
  static const AppRoute settingsPage = AppRoute('/settings');

  // Inventory Sub Pages
  static const AppRoute categoriesPage = AppRoute('/categories');
  static const AppRoute createProductPage = AppRoute('/create/product');
  static const AppRoute editProductPage = AppRoute('/edit');

  // Security Sub Pages
  static const AppRoute usersPage = AppRoute('/users');
  static const AppRoute createUserPage = AppRoute('/create/user');
  static const AppRoute userLogsPage = AppRoute('/logs');
}

/// A zero-cost compile-time wrapper for a string path.
///   This is used to define and use routes in a type-safe manner.
extension type const AppRoute(String path) {}
