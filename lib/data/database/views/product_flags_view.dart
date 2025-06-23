import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class ProductFlagsView {
  static const String PRODUCT_STATUS_VIEW_TABLE = 'product_status_view';
  static Future<void> createView(DatabaseExecutor database) async {
    await database.execute('''
      CREATE VIEW $PRODUCT_STATUS_VIEW_TABLE AS
      WITH
      -- Sales per day per product in the last 30 days
      daily_sales AS (
        SELECT
        ip.product_id,
        DATE(i.invoice_date) AS sale_date,
        COUNT(*) AS sales
        FROM invoice_products ip
        JOIN invoices i ON ip.invoice_id = i.id
        WHERE DATE(i.invoice_date) >= DATE('now', '-30 days')
        GROUP BY ip.product_id, DATE(i.invoice_date)
      ),

      -- Max daily sales per product
      max_daily_sales AS (
        SELECT
        product_id,
        MAX(sales) AS max_daily_sales
        FROM daily_sales
        GROUP BY product_id
      ),

      -- Average daily sales per product
      average_daily_sales AS (
        SELECT
        product_id,
        AVG(sales) AS avg_daily_sales
        FROM daily_sales
        GROUP BY product_id
      ),

      -- Estimated average lead time per product
      avg_lead_times AS (
        SELECT
        id as product_id,
        ((max_reorder_delay - min_reorder_delay) / 2.0) AS avg_delay
        FROM products
      ),

      -- Lead time demand = avg_daily_sales * avg_delay
      lead_time_demand AS (
        SELECT
        ads.product_id,
        ads.avg_daily_sales * alt.avg_delay AS lead_time_demand
        FROM average_daily_sales ads
        JOIN avg_lead_times alt ON ads.product_id = alt.product_id
      ),

      -- Safety stock = max_daily_sales * max_reorder_delay - avg_daily_sales * avg_delay
      safety_stock AS (
        SELECT
        mds.product_id,
        (mds.max_daily_sales * p.max_reorder_delay) -
        (ads.avg_daily_sales * alt.avg_delay) AS safety_stock
        FROM max_daily_sales mds
        JOIN average_daily_sales ads ON mds.product_id = ads.product_id
        JOIN avg_lead_times alt ON mds.product_id = alt.product_id
        JOIN products p ON mds.product_id = p.id
      ),

      -- Reorder point = safety stock + lead time demand
      reorder_point AS (
        SELECT
        ss.product_id,
        ss.safety_stock + ltd.lead_time_demand AS reorder_point
        FROM safety_stock ss
        JOIN lead_time_demand ltd ON ss.product_id = ltd.product_id
      ),

      -- Last invoice date per product
      last_sale_dates AS (
        SELECT
        ip.product_id,
        MAX(DATE(i.invoice_date)) AS last_sale_date
        FROM invoice_products ip
        JOIN invoices i ON ip.invoice_id = i.id
        GROUP BY ip.product_id
      ),

      -- Count of sales in last 14 days per product
      recent_sales AS (
        SELECT
        ip.product_id,
        COUNT(*) AS recent_sale_count
        FROM invoice_products ip
        JOIN invoices i ON ip.invoice_id = i.id
        WHERE DATE(i.invoice_date) >= DATE('now', '-14 days')
        GROUP BY ip.product_id
      )

      -- Final output
      SELECT
      p.*,
      COALESCE(rp.reorder_point, 0) AS reorder_point,
      COALESCE(rs.recent_sale_count, 0) AS recent_sales,

      -- Fast-moving flag
      CASE
      WHEN rs.recent_sale_count >= p.fast_moving_threshold THEN 1
      ELSE 0
      END AS is_fast_moving,

      -- Dead stock flag
      CASE
      WHEN lsd.last_sale_date IS NULL
        AND DATE(p.creation_date) <= DATE('now', '-' || p.dead_stock_threshold || ' days')
      OR (lsd.last_sale_date IS NOT NULL
        AND lsd.last_sale_date < DATE('now', '-' || p.dead_stock_threshold || ' days')
        AND DATE(p.creation_date) <= DATE('now', '-' || p.dead_stock_threshold || ' days'))
      THEN 1 ELSE 0
      END AS is_dead_stock,

      -- Below critical level flag
      CASE
      WHEN DATE(p.creation_date) <= DATE('now', '-30 days')
      THEN CASE
        WHEN p.quantity <= COALESCE(rp.reorder_point, 999999) THEN 1
        ELSE 0
      END
      ELSE CASE
      WHEN p.quantity <= p.critical_level THEN 1
      ELSE 0
      END
      END AS is_below_critical_level

      FROM products p
      LEFT JOIN recent_sales rs ON p.id = rs.product_id
      LEFT JOIN last_sale_dates lsd ON p.id = lsd.product_id
      LEFT JOIN reorder_point rp ON p.id = rp.product_id;
    ''');
  }

  //"  AND date(p.creation_date) <= date('now', '-' || dead_stock_threshold || ' days')"
  static Future<void> dropView(DatabaseExecutor database) async {
    await database.execute('DROP VIEW IF EXISTS $PRODUCT_STATUS_VIEW_TABLE');
  }
}
