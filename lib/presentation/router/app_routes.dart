import 'package:easthardware_pms/domain/models/invoice.dart';
import 'package:easthardware_pms/domain/models/order.dart';
import 'package:easthardware_pms/domain/models/product.dart';
import 'package:easthardware_pms/utils/typed_routes.dart';

class AppRoutes {
  static const root = AppRoute<Null>('/');
  static const login = AppRoute<Null>('/login');
  static const resetPassword = AppRoute<String>('/reset_password_authentication');
  static const newPassword = AppRoute<String>('/new_password');

  // static const inventory = AppRoute<Null>('/inventory');
  // static const billing = AppRoute<Null>('/billing');
  // static const order = AppRoute<Null>('/order');
  // static const reports = AppRoute<Null>('/reports_list');
  // static const settings = AppRoute<Null>('/settings');
  // static const help = AppRoute<Null>('/help');
  // static const about = AppRoute<Null>('/about');

  // Major Page Routes
  static const admin = (
    dashboard: AppRoute<Null>('/admin/dashboard'),
    inventory: AppRoute<Null>('/admin/inventory'),
    billing: AppRoute<Null>('/admin/billing'),
    payment: AppRoute<Null>('/admin/payment'),
    order: AppRoute<Null>('/admin/order'),
    reports: AppRoute<Null>('/admin/reports'),
    settings: AppRoute<Null>('/admin/settings'),

    // Inventory Sub Pages
    categories: AppRoute<Null>('/admin/categories'),
    createProduct: AppRoute<Null>('/admin/create/product'),
    editProduct: AppRoute<Product>('/admin/edit/product'),

    // Search Pages
    search: (
      products: AppRoute<Null>('/admin/search/products'),
      invoices: AppRoute<Null>('/admin/search/invoices'),
      orders: AppRoute<Null>('/admin/search/orders'),
    ),

    // Billing Sub Pages
    createInvoice: AppRoute<Null>('/admin/create/invoice'),

    // Payment Sub Pages
    createPayment: (
      withInvoice: AppRoute<Invoice>('/admin/create/payment'),
      withoutInvoice: AppRoute<Null>('/admin/create/payment'),
      route: AppRoute<Invoice?>('/admin/create/payment'),
    ),

    //Order Sub Pages
    createRestockOrder: (
      withProduct: AppRoute<Product>('/admin/create/restock_order'),
      withoutProduct: AppRoute<Null>('/admin/create/restock_order'),
      route: AppRoute<Product?>('/admin/create/restock_order'),
    ),
    editRestockOrder: AppRoute<Order>('/admin/edit/restock_order'),
    editExpenseOrder: AppRoute<Order>('/admin/edit/expense_order'),
    createExpenseOrder: AppRoute<Null>('/admin/create/expense_order'),
    manageExpenseType: AppRoute<Null>('/admin/manage/expense_type'),

    // Reports Sub Pages
    inventoryReport: AppRoute<Null>('/admin/reports/inventory'),
    salesByProductReport: AppRoute<Null>('/admin/reports/sales_by_product'),
    salesByCategoryReport: AppRoute<Null>('/admin/reports/sales_by_category'),

    // Security Sub Pages
    users: AppRoute<Null>('/admin/users'),
    createUser: AppRoute<Null>('/admin/create/user'),
    userLogs: AppRoute<Null>('/admin/logs'),

    // Settings Sub Pages
    help: AppRoute<Null>('/admin/help'),
    about: AppRoute<Null>('/admin/about'),
  );

  static const staff = (
    dashboard: AppRoute<Null>('/staff/dashboard'),
    inventory: AppRoute<Null>('/staff/inventory'),
    search: (
      products: AppRoute<Null>('/staff/search/products'),
      invoices: AppRoute<Null>('/staff/search/invoices'),
      orders: AppRoute<Null>('/staff/search/orders'),
    ),
    billing: AppRoute<Null>('/staff/billing'),
    createInvoice: AppRoute<Null>('/staff/create/invoice'),
    payInvoice: AppRoute<Null>('/staff/pay/invoice'),
    help: AppRoute<Null>('/staff/help'),
    about: AppRoute<Null>('/staff/about'),
  );

  // static const admin = AppRoute<Null>('/admin');
  // static const staff = AppRoute<Null>('/staff');
  // static const inventoryPage = AppRoute<Null>('/inventory');
  // static const billingPage = AppRoute<Null>('/billing');
  // static const orderPage = AppRoute<Null>('/order');
  // static const reportsPage = AppRoute<Null>('/reports');
  // static const settingsPage = AppRoute<Null>('/settings');

  // // Inventory Sub Pages
  // static const categoriesPage = AppRoute<Null>('/categories');
  // static const createProductPage = AppRoute<Null>('/create/product');
  // static const editProductPage = AppRoute<Product>('/edit');

  // // Billing SubPages
  // static const createInvoicePage = AppRoute<Null>('/create/invoice');
  // static const String payInvoicePage = 'pay/invoice';

  // // Security Sub Pages
  // static const usersPage = AppRoute<Null>('/users');
  // static const createUserPage = AppRoute<Null>('/create/user');
  // static const userLogsPage = AppRoute<Null>('/logs');
}
