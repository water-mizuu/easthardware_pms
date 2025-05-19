import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class ProductFlagsView {
  static const String PRODUCT_STATUS_VIEW_TABLE = 'product_status_view';
  static void createView(Database database) async {
    await database.execute('''
      CREATE VIEW $PRODUCT_STATUS_VIEW_TABLE AS
      SELECT p.*,
          CASE
            WHEN (
              SELECT COUNT(*)
              FROM invoice_products ip
              JOIN invoices i ON ip.invoice_id = i.id
              WHERE ip.product_id = p.id
              AND date(i.invoice_date) >= date('now', '-14 days')
            ) >= p.fast_moving_threshold
            THEN 1 ELSE 0
          END AS is_fast_moving,
          CASE
            WHEN (
              SELECT MAX(date(i.invoice_date))
              FROM invoice_products ip
              JOIN invoices i ON ip.invoice_id = i.id
              WHERE ip.product_id = p.id
            ) IS NULL
            AND date(p.creation_date) <= date('now', '-' || p.dead_stock_threshold || ' days')

            OR (
              SELECT MAX(date(i.invoice_date))
              FROM invoice_products ip
              JOIN invoices i ON ip.invoice_id = i.id
              WHERE ip.product_id = p.id
            ) < date('now', '-' || p.dead_stock_threshold || ' days')
            AND date(p.creation_date) <= date('now', '-' || p.dead_stock_threshold || ' days')

            THEN 1 ELSE 0
          END AS is_dead_stock,
          CASE
            WHEN p.quantity <= p.critical_level THEN 1 ELSE 0
          END AS is_below_critical_level
      FROM products p;
    ''');
  }

  //"  AND date(p.creation_date) <= date('now', '-' || dead_stock_threshold || ' days')"
  static void dropView(Database database) async {
    await database.execute('DROP VIEW IF EXISTS $PRODUCT_STATUS_VIEW_TABLE');
  }
}
