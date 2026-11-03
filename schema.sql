-- schema.sql
-- Duka Smart Electronics: retail_analytics schema (PostgreSQL 14+)
--
-- Run connected to the retail_analytics database:
--   psql -U postgres -d retail_analytics -f schema.sql
--
-- To create the database first (run connected to the default postgres database):
--   CREATE DATABASE retail_analytics;
--
-- Safe to re-run: IF NOT EXISTS leaves existing tables and data untouched.
-- To rebuild from scratch, uncomment the two DROP lines (orders first, because it references customers).

-- DROP TABLE IF EXISTS orders;
-- DROP TABLE IF EXISTS customers;

CREATE TABLE IF NOT EXISTS customers (
    customer_id        INTEGER      PRIMARY KEY,
    customer_name      VARCHAR(100) NOT NULL,
    gender             VARCHAR(10)  CHECK (gender IN ('Male', 'Female')),
    city               VARCHAR(50),
    registration_date  DATE,
    customer_segment   VARCHAR(20)  CHECK (customer_segment IN ('Retail', 'Corporate', 'VIP'))
);

CREATE TABLE IF NOT EXISTS orders (
    order_id          INTEGER       PRIMARY KEY,
    customer_id       INTEGER       NOT NULL REFERENCES customers (customer_id),
    order_date        DATE          NOT NULL,
    product_name      VARCHAR(100),
    product_category  VARCHAR(50),
    quantity          INTEGER       CHECK (quantity > 0),
    unit_price        NUMERIC(12,2) CHECK (unit_price >= 0),
    cost_price        NUMERIC(12,2) CHECK (cost_price >= 0),
    discount          NUMERIC(5,2)  DEFAULT 0 CHECK (discount BETWEEN 0 AND 100),
    payment_method    VARCHAR(30)   CHECK (payment_method IN ('M-Pesa', 'Cash', 'Card', 'Bank Transfer')),
    order_status      VARCHAR(20)   CHECK (order_status IN ('Completed', 'Pending', 'Cancelled'))
);

-- Indexes for the two access paths used throughout the analysis: joins on customer_id and date filters.
CREATE INDEX IF NOT EXISTS idx_orders_customer ON orders (customer_id);
CREATE INDEX IF NOT EXISTS idx_orders_date     ON orders (order_date);
CREATE INDEX IF NOT EXISTS idx_orders_status   ON orders (order_status);

-- Column documentation (visible in pgAdmin and with \d+ in psql).
COMMENT ON TABLE  customers                   IS 'One row per customer (150 rows).';
COMMENT ON TABLE  orders                      IS 'One row per order (800 rows). Money questions use Completed orders only.';
COMMENT ON COLUMN orders.unit_price           IS 'Selling price per unit in KSh, before discount.';
COMMENT ON COLUMN orders.cost_price           IS 'Cost of one unit to the company, in KSh.';
COMMENT ON COLUMN orders.discount             IS 'Discount percentage: 10 means 10 percent off.';
COMMENT ON COLUMN customers.registration_date IS 'When the customer joined; never after their first order.';
