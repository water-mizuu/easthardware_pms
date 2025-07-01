-- Database Schema for EastHardware PMS
-- Complete SQL Table Definitions

-- ============================================================================
-- CORE TABLES
-- ============================================================================

-- Categories Table
CREATE TABLE categories (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL UNIQUE,
  archive_status INTEGER DEFAULT 0
);

-- Users Table  
CREATE TABLE users (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  uid TEXT NOT NULL,
  username TEXT NOT NULL,
  password_hash TEXT NOT NULL,
  first_name TEXT NOT NULL,
  last_name TEXT NOT NULL,
  access_level INTEGER NOT NULL,
  salt TEXT NOT NULL,
  creation_date TEXT NOT NULL,
  archive_status INTEGER NOT NULL,
  login_status INTEGER NOT NULL
);

-- Security Questions Table
CREATE TABLE security_questions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER NOT NULL,
  question TEXT NOT NULL,
  answer TEXT NOT NULL,
  FOREIGN KEY (user_id) REFERENCES users(id)
);

-- Payment Methods Table
CREATE TABLE payment_methods (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  archive_status INTEGER DEFAULT 0
);

-- Expense Types Table
CREATE TABLE expense_types (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL UNIQUE,
  archive_status INTEGER DEFAULT 0
);

-- ============================================================================
-- PRODUCT MANAGEMENT TABLES
-- ============================================================================

-- Products Table
CREATE TABLE products (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL UNIQUE,
  sku TEXT NOT NULL UNIQUE,
  category INTEGER,
  description TEXT,
  sale_price REAL NOT NULL,
  order_cost REAL NOT NULL,
  quantity REAL NOT NULL,
  main_unit STRING NOT NULL,
  min_reorder_delay INTEGER NOT NULL,
  max_reorder_delay INTEGER NOT NULL,
  dead_stock_threshold REAL NOT NULL,
  fast_moving_threshold REAL NOT NULL,
  creation_date TEXT NOT NULL,
  creator_id INTEGER NOT NULL,
  archive_status INTEGER NOT NULL,
  FOREIGN KEY(category) REFERENCES categories(id),
  FOREIGN KEY(creator_id) REFERENCES users(id)
);

-- Units Table
CREATE TABLE units (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  product_id INTEGER NOT NULL,
  main_quantity INTEGER NOT NULL,
  unit_quantity INTEGER NOT NULL,
  FOREIGN KEY(product_id) REFERENCES products(id)
);

-- ============================================================================
-- ORDER MANAGEMENT TABLES
-- ============================================================================

-- Orders Table
CREATE TABLE orders (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  uid TEXT NOT NULL,
  payee_name TEXT NOT NULL,
  expense_type INTEGER NOT NULL,
  order_date TEXT NOT NULL,
  payment_method INTEGER NOT NULL,
  reference_number TEXT,
  memo TEXT,
  amount_due REAL NOT NULL,
  amount_paid REAL,
  payment_date TEXT,
  creation_date TEXT NOT NULL,
  creator_id INTEGER NOT NULL,
  FOREIGN KEY(expense_type) REFERENCES expense_types(id),
  FOREIGN KEY(payment_method) REFERENCES payment_methods(id),
  FOREIGN KEY(creator_id) REFERENCES users(id)
);

-- Order Items Table
CREATE TABLE order_items (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  order_id INTEGER NOT NULL,
  name TEXT NOT NULL,
  description TEXT,
  quantity INTEGER NOT NULL,
  rate REAL NOT NULL,
  amount REAL NOT NULL,
  FOREIGN KEY(order_id) REFERENCES orders(id)
);

-- Order Products Table
CREATE TABLE order_products (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  order_id INTEGER NOT NULL,
  product_id INTEGER,
  name TEXT NOT NULL,
  description TEXT,
  quantity INTEGER NOT NULL,
  secondary_unit INT,
  conversion_factor REAL,
  rate REAL NOT NULL,
  amount REAL NOT NULL,
  FOREIGN KEY(order_id) REFERENCES orders(id),
  FOREIGN KEY(product_id) REFERENCES products(id),
  FOREIGN KEY(secondary_unit) REFERENCES units(id)
);

-- ============================================================================
-- INVOICE MANAGEMENT TABLES
-- ============================================================================

-- Invoices Table
CREATE TABLE invoices (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  customer_name TEXT,
  invoice_date TEXT NOT NULL,
  due_date TEXT NOT NULL,
  payment_method INTEGER,
  reference_number TEXT,
  memo TEXT,
  discount REAL,
  discount_type INTEGER,
  amount_due REAL NOT NULL,
  amount_paid REAL,
  payment_date TEXT,
  creation_date TEXT NOT NULL,
  creator_id INTEGER NOT NULL,
  FOREIGN KEY(payment_method) REFERENCES payment_methods(id),
  FOREIGN KEY(creator_id) REFERENCES users(id)
);

-- Invoice Products Table
CREATE TABLE invoice_products (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  invoice_id INTEGER NOT NULL,
  product_id INTEGER NOT NULL,
  product_name TEXT NOT NULL,
  description TEXT,
  quantity INTEGER NOT NULL,
  secondary_unit INTEGER,
  conversion_factor REAL,
  rate REAL NOT NULL,
  amount REAL NOT NULL,
  FOREIGN KEY(invoice_id) REFERENCES invoices(id),
  FOREIGN KEY(product_id) REFERENCES products(id),
  FOREIGN KEY(secondary_unit) REFERENCES units(id)
);

-- Payments Table
CREATE TABLE payments (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  invoice_id INTEGER NOT NULL,
  amount REAL NOT NULL,
  payment_date TEXT NOT NULL,
  payment_method INTEGER NOT NULL,
  reference_number TEXT,
  creator_id INTEGER NOT NULL,
  creation_date TEXT NOT NULL,
  FOREIGN KEY(invoice_id) REFERENCES invoices(id),
  FOREIGN KEY(payment_method) REFERENCES payment_methods(id),
  FOREIGN KEY(creator_id) REFERENCES users(id)
);

-- ============================================================================
-- AUDIT AND LOGGING TABLES
-- ============================================================================

-- User Logs Table
CREATE TABLE user_logs (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  uid TEXT NOT NULL,
  user_id INTEGER NOT NULL,
  event TEXT NOT NULL,
  event_time TEXT NOT NULL,
  FOREIGN KEY(user_id) REFERENCES users(id)
);

-- ============================================================================
-- VIEWS
-- ============================================================================

-- Product Status View (for inventory management flags)
CREATE VIEW product_status_view AS
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
  
  -- Fixed average lead time per product
  avg_lead_times AS (
    SELECT
      id as product_id,
      (min_reorder_delay + max_reorder_delay) / 2.0 AS avg_delay
    FROM products
    WHERE min_reorder_delay IS NOT NULL 
    AND max_reorder_delay IS NOT NULL
  ),
  
  -- Lead time demand = avg_daily_sales * avg_delay
  lead_time_demand AS (
    SELECT
      ads.product_id,
      COALESCE(ads.avg_daily_sales, 0) * COALESCE(alt.avg_delay, 0) AS lead_time_demand
    FROM average_daily_sales ads
    LEFT JOIN avg_lead_times alt ON ads.product_id = alt.product_id
  ),
  
  -- Safety stock with bound checking
  safety_stock AS (
    SELECT
      p.id as product_id,
      MAX(0, 
        COALESCE(mds.max_daily_sales, 0) - COALESCE(ads.avg_daily_sales, 0)
      ) * COALESCE(alt.avg_delay, 0) AS safety_stock
    FROM products p
    LEFT JOIN max_daily_sales mds ON p.id = mds.product_id
    LEFT JOIN average_daily_sales ads ON p.id = ads.product_id
    LEFT JOIN avg_lead_times alt ON p.id = alt.product_id
  ),
  
  -- Reorder point calculation
  reorder_points AS (
    SELECT
      ltd.product_id,
      COALESCE(ltd.lead_time_demand, 0) + COALESCE(ss.safety_stock, 0) AS reorder_point
    FROM lead_time_demand ltd
    LEFT JOIN safety_stock ss ON ltd.product_id = ss.product_id
  ),
  
  -- Last sale date per product
  last_sales AS (
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
  
  -- Fast-moving flag (with null handling)
  CASE
    WHEN COALESCE(rs.recent_sale_count, 0) >= COALESCE(p.fast_moving_threshold, 999999) THEN 1
    ELSE 0
  END AS is_fast_moving,
  
  -- Low stock flag (reorder point comparison)
  CASE
    WHEN p.quantity <= COALESCE(rp.reorder_point, 0) THEN 1
    ELSE 0
  END AS is_low_stock,
  
  -- Dead stock flag (simplified)
  CASE
    WHEN COALESCE(rs.recent_sale_count, 0) <= COALESCE(p.dead_stock_threshold, 0) THEN 1
    ELSE 0
  END AS is_dead_stock

FROM products p
LEFT JOIN reorder_points rp ON p.id = rp.product_id
LEFT JOIN recent_sales rs ON p.id = rs.product_id;

-- ============================================================================
-- DEFAULT DATA INSERTIONS
-- ============================================================================

-- Default Expense Type
INSERT INTO expense_types (id, name) VALUES (1, 'Inventory Restock');