-- queries.sql | Duka Smart Electronics | PostgreSQL 14+
-- Run connected to retail_analytics:  psql -U postgres -d retail_analytics -f queries.sql
--
-- Business rules used throughout (README section 7):
--   revenue = quantity * unit_price * (1 - discount / 100)      cost = quantity * cost_price
--   Money questions use Completed orders only; order counts use every order.
--   "Today" is MAX(order_date) in the data.

-- ============================ SECTION A: FUNDAMENTALS ============================

-- Q1: Retrieve all customer records
SELECT * FROM customers;

-- Q2: Display customer names, cities, and segments
SELECT customer_name, city, customer_segment FROM customers;

-- Q3: Find customers living in Nairobi
SELECT * FROM customers WHERE city = 'Nairobi';

-- Q4: Find customers registered after January 1, 2025
SELECT * FROM customers WHERE registration_date > '2025-01-01' ORDER BY registration_date;

-- Q5: Display all unique customer cities
SELECT DISTINCT city FROM customers ORDER BY city;

-- Q6: Retrieve the 10 most recent orders
SELECT * FROM orders ORDER BY order_date DESC, order_id DESC LIMIT 10;

-- Q7: Find orders with unit prices above KSh 10,000
SELECT * FROM orders WHERE unit_price > 10000;

-- Q8: Find customers whose names start with A
SELECT * FROM customers WHERE customer_name LIKE 'A%';

-- Q9: Retrieve orders with quantities between 2 and 5
SELECT * FROM orders WHERE quantity BETWEEN 2 AND 5;

-- Q10: Find orders paid through M-Pesa
SELECT * FROM orders WHERE payment_method = 'M-Pesa';

-- ============================ SECTION B: AGGREGATION ============================

-- Q11: Count all customers
SELECT COUNT(*) AS total_customers FROM customers;

-- Q12: Count all orders (every status)
SELECT COUNT(*) AS total_orders FROM orders;

-- Q13: Calculate completed-order revenue
SELECT ROUND(SUM(quantity * unit_price * (1 - discount / 100)), 2) AS completed_revenue
FROM orders
WHERE order_status = 'Completed';

-- Q14: Calculate the average completed-order value
SELECT ROUND(AVG(quantity * unit_price * (1 - discount / 100)), 2) AS avg_order_value
FROM orders
WHERE order_status = 'Completed';

-- Q15: Find the highest and lowest product prices
SELECT MAX(unit_price) AS highest_price, MIN(unit_price) AS lowest_price FROM orders;

-- Q16: Calculate revenue by product category
SELECT product_category, ROUND(SUM(quantity * unit_price * (1 - discount / 100)), 2) AS revenue
FROM orders
WHERE order_status = 'Completed'
GROUP BY product_category
ORDER BY revenue DESC;

-- Q17: Count customers by city
SELECT city, COUNT(*) AS customers FROM customers GROUP BY city ORDER BY customers DESC;

-- Q18: Calculate quantity sold by product (completed orders = units actually sold)
SELECT product_name, SUM(quantity) AS units_sold
FROM orders
WHERE order_status = 'Completed'
GROUP BY product_name
ORDER BY units_sold DESC;

-- Q19: Find categories generating more than KSh 100,000 in revenue
SELECT product_category, ROUND(SUM(quantity * unit_price * (1 - discount / 100)), 2) AS revenue
FROM orders
WHERE order_status = 'Completed'
GROUP BY product_category
HAVING SUM(quantity * unit_price * (1 - discount / 100)) > 100000
ORDER BY revenue DESC;

-- Q20: Calculate the percentage of cancelled orders (of all orders)
SELECT ROUND(100.0 * COUNT(*) FILTER (WHERE order_status = 'Cancelled') / COUNT(*), 2) AS cancelled_pct
FROM orders;

-- ============================ SECTION C: JOINS ============================

-- Q21: Display orders with customer names and cities
SELECT o.order_id, o.order_date, c.customer_name, c.city, o.product_name, o.order_status
FROM orders o
JOIN customers c ON c.customer_id = o.customer_id
ORDER BY o.order_id;

-- Q22: Calculate total spending by customer (completed orders)
SELECT c.customer_id, c.customer_name,
       ROUND(SUM(o.quantity * o.unit_price * (1 - o.discount / 100)), 2) AS total_spending
FROM customers c
JOIN orders o ON o.customer_id = c.customer_id
WHERE o.order_status = 'Completed'
GROUP BY c.customer_id, c.customer_name
ORDER BY total_spending DESC;

-- Q23: Identify customers who have never ordered (any status)
SELECT c.customer_id, c.customer_name, c.city, c.customer_segment
FROM customers c
LEFT JOIN orders o ON o.customer_id = c.customer_id
WHERE o.order_id IS NULL
ORDER BY c.customer_id;

-- Q24: Find the 10 highest-spending customers
SELECT c.customer_id, c.customer_name,
       ROUND(SUM(o.quantity * o.unit_price * (1 - o.discount / 100)), 2) AS total_spending
FROM customers c
JOIN orders o ON o.customer_id = c.customer_id
WHERE o.order_status = 'Completed'
GROUP BY c.customer_id, c.customer_name
ORDER BY total_spending DESC
LIMIT 10;

-- Q25: Calculate revenue by customer city
SELECT c.city, ROUND(SUM(o.quantity * o.unit_price * (1 - o.discount / 100)), 2) AS revenue
FROM customers c
JOIN orders o ON o.customer_id = c.customer_id
WHERE o.order_status = 'Completed'
GROUP BY c.city
ORDER BY revenue DESC;

-- Q26: Identify customers with more than five orders (all statuses)
SELECT c.customer_id, c.customer_name, COUNT(*) AS orders
FROM customers c
JOIN orders o ON o.customer_id = c.customer_id
GROUP BY c.customer_id, c.customer_name
HAVING COUNT(*) > 5
ORDER BY orders DESC;

-- Q27: Average customer spending by segment
-- Definition: each purchasing customer's completed total first, then the average of those totals per segment.
WITH totals AS (
    SELECT customer_id, SUM(quantity * unit_price * (1 - discount / 100)) AS total
    FROM orders
    WHERE order_status = 'Completed'
    GROUP BY customer_id
)
SELECT c.customer_segment, COUNT(*) AS buying_customers, ROUND(AVG(t.total), 2) AS avg_spending
FROM totals t
JOIN customers c ON c.customer_id = t.customer_id
GROUP BY c.customer_segment
ORDER BY avg_spending DESC;

-- Q28: Most popular category among VIP customers
-- "Popular" = number of completed orders (units sold break ties).
SELECT o.product_category, COUNT(*) AS orders, SUM(o.quantity) AS units
FROM orders o
JOIN customers c ON c.customer_id = o.customer_id
WHERE c.customer_segment = 'VIP' AND o.order_status = 'Completed'
GROUP BY o.product_category
ORDER BY orders DESC, units DESC
LIMIT 1;

-- ============================ SECTION D: SUBQUERIES & CTEs ============================

-- Q29: Customers spending above the average total per purchasing customer
WITH totals AS (
    SELECT customer_id, SUM(quantity * unit_price * (1 - discount / 100)) AS total
    FROM orders
    WHERE order_status = 'Completed'
    GROUP BY customer_id
)
SELECT c.customer_id, c.customer_name, ROUND(t.total, 2) AS total_spending
FROM totals t
JOIN customers c ON c.customer_id = t.customer_id
WHERE t.total > (SELECT AVG(total) FROM totals)
ORDER BY t.total DESC;

-- Q30: Products priced above the overall average unit price (average taken over all orders)
SELECT DISTINCT product_name, unit_price
FROM orders
WHERE unit_price > (SELECT AVG(unit_price) FROM orders)
ORDER BY unit_price DESC;

-- Q31: Three highest-revenue months
WITH monthly AS (
    SELECT DATE_TRUNC('month', order_date)::date AS month,
           SUM(quantity * unit_price * (1 - discount / 100)) AS revenue
    FROM orders
    WHERE order_status = 'Completed'
    GROUP BY 1
)
SELECT month, ROUND(revenue, 2) AS revenue FROM monthly ORDER BY revenue DESC LIMIT 3;

-- Q32: Customers purchasing from at least three categories (completed orders)
SELECT c.customer_id, c.customer_name, COUNT(DISTINCT o.product_category) AS categories
FROM customers c
JOIN orders o ON o.customer_id = c.customer_id
WHERE o.order_status = 'Completed'
GROUP BY c.customer_id, c.customer_name
HAVING COUNT(DISTINCT o.product_category) >= 3
ORDER BY categories DESC, c.customer_id;

-- Q33: Category revenue, cost, profit and profit margin
WITH cat AS (
    SELECT product_category,
           SUM(quantity * unit_price * (1 - discount / 100)) AS revenue,
           SUM(quantity * cost_price)                         AS cost
    FROM orders
    WHERE order_status = 'Completed'
    GROUP BY product_category
)
SELECT product_category,
       ROUND(revenue, 2)                                      AS revenue,
       ROUND(cost, 2)                                         AS cost,
       ROUND(revenue - cost, 2)                               AS profit,
       ROUND((revenue - cost) / NULLIF(revenue, 0) * 100, 2)  AS margin_pct
FROM cat
ORDER BY profit DESC;

-- Q34: Customers whose latest completed order is more than 90 days before the dataset's latest order date
WITH last_order AS (
    SELECT customer_id, MAX(order_date) AS last_date
    FROM orders
    WHERE order_status = 'Completed'
    GROUP BY customer_id
)
SELECT c.customer_id, c.customer_name, l.last_date,
       (SELECT MAX(order_date) FROM orders) - l.last_date AS days_inactive
FROM last_order l
JOIN customers c ON c.customer_id = l.customer_id
WHERE (SELECT MAX(order_date) FROM orders) - l.last_date > 90
ORDER BY days_inactive DESC;

-- ============================ SECTION E: WINDOW FUNCTIONS ============================

-- Q35: Rank customers by spending using RANK()
WITH spend AS (
    SELECT customer_id, SUM(quantity * unit_price * (1 - discount / 100)) AS total
    FROM orders
    WHERE order_status = 'Completed'
    GROUP BY customer_id
)
SELECT c.customer_name, ROUND(s.total, 2) AS total_spending,
       RANK() OVER (ORDER BY s.total DESC) AS spend_rank
FROM spend s
JOIN customers c ON c.customer_id = s.customer_id
ORDER BY spend_rank;

-- Q36: Number each customer's orders by recency (1 = most recent), all orders
SELECT customer_id, order_id, order_date,
       ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY order_date DESC, order_id DESC) AS recency_no
FROM orders
ORDER BY customer_id, recency_no;

-- Q37: Rank products within categories by revenue using DENSE_RANK()
WITH prod AS (
    SELECT product_category, product_name,
           SUM(quantity * unit_price * (1 - discount / 100)) AS revenue
    FROM orders
    WHERE order_status = 'Completed'
    GROUP BY product_category, product_name
)
SELECT product_category, product_name, ROUND(revenue, 2) AS revenue,
       DENSE_RANK() OVER (PARTITION BY product_category ORDER BY revenue DESC) AS rank_in_category
FROM prod
ORDER BY product_category, rank_in_category;

-- Q38: Cumulative monthly revenue
WITH monthly AS (
    SELECT DATE_TRUNC('month', order_date)::date AS month,
           SUM(quantity * unit_price * (1 - discount / 100)) AS revenue
    FROM orders
    WHERE order_status = 'Completed'
    GROUP BY 1
)
SELECT month, ROUND(revenue, 2) AS revenue,
       ROUND(SUM(revenue) OVER (ORDER BY month), 2) AS cumulative_revenue
FROM monthly
ORDER BY month;

-- Q39: Compare monthly revenue with the previous month using LAG()
WITH monthly AS (
    SELECT DATE_TRUNC('month', order_date)::date AS month,
           SUM(quantity * unit_price * (1 - discount / 100)) AS revenue
    FROM orders
    WHERE order_status = 'Completed'
    GROUP BY 1
)
SELECT month, ROUND(revenue, 2) AS revenue,
       ROUND(LAG(revenue) OVER (ORDER BY month), 2) AS previous_month_revenue
FROM monthly
ORDER BY month;

-- Q40: Month-over-month revenue growth (%)
WITH monthly AS (
    SELECT DATE_TRUNC('month', order_date)::date AS month,
           SUM(quantity * unit_price * (1 - discount / 100)) AS revenue
    FROM orders
    WHERE order_status = 'Completed'
    GROUP BY 1
)
SELECT month, ROUND(revenue, 2) AS revenue,
       ROUND(100 * (revenue / NULLIF(LAG(revenue) OVER (ORDER BY month), 0) - 1), 2) AS growth_pct
FROM monthly
ORDER BY month;

-- Q41: Divide customers into four spending groups using NTILE(4) (1 = highest spenders)
WITH totals AS (
    SELECT customer_id, SUM(quantity * unit_price * (1 - discount / 100)) AS total
    FROM orders
    WHERE order_status = 'Completed'
    GROUP BY customer_id
)
SELECT c.customer_id, c.customer_name, ROUND(t.total, 2) AS total_spending,
       NTILE(4) OVER (ORDER BY t.total DESC) AS spending_group
FROM totals t
JOIN customers c ON c.customer_id = t.customer_id
ORDER BY spending_group, t.total DESC;

-- Q42: Each category's share of total revenue
WITH cat AS (
    SELECT product_category, SUM(quantity * unit_price * (1 - discount / 100)) AS revenue
    FROM orders
    WHERE order_status = 'Completed'
    GROUP BY product_category
)
SELECT product_category, ROUND(revenue, 2) AS revenue,
       ROUND(100 * revenue / SUM(revenue) OVER (), 2) AS share_pct
FROM cat
ORDER BY share_pct DESC;

-- ============================ SECTION F: ADVANCED BI ============================

-- Q43: monthly_sales_summary view (orders = every order that month; money = completed orders only)
CREATE OR REPLACE VIEW monthly_sales_summary AS
SELECT month, orders,
       ROUND(revenue, 2)        AS revenue,
       ROUND(cost, 2)           AS cost,
       ROUND(revenue - cost, 2) AS profit
FROM (
    SELECT DATE_TRUNC('month', order_date)::date AS month,
           COUNT(*) AS orders,
           COALESCE(SUM(quantity * unit_price * (1 - discount / 100)) FILTER (WHERE order_status = 'Completed'), 0) AS revenue,
           COALESCE(SUM(quantity * cost_price) FILTER (WHERE order_status = 'Completed'), 0) AS cost
    FROM orders
    GROUP BY 1
) t;

SELECT * FROM monthly_sales_summary ORDER BY month;

-- Q44: Function returning completed-order revenue for a customer (0 if none / unknown ID)
CREATE OR REPLACE FUNCTION customer_revenue(p_id INTEGER)
RETURNS NUMERIC LANGUAGE plpgsql AS $$
DECLARE v_result NUMERIC;
BEGIN
    SELECT COALESCE(SUM(quantity * unit_price * (1 - discount / 100)), 0)
    INTO v_result
    FROM orders
    WHERE customer_id = p_id AND order_status = 'Completed';
    RETURN ROUND(v_result, 2);
END;
$$;

SELECT customer_revenue(65)    AS existing_customer,    -- has completed orders
       customer_revenue(99999) AS nonexistent_customer; -- returns 0, not NULL

-- Q45: Segment customers into High / Medium / Low Value
-- Thresholds: percentiles of completed spending among buying customers.
--   High   = top 25% (>= 75th percentile)      Low = bottom 25% (< 25th percentile) or never bought
--   Medium = the middle 50%
-- Percentiles adapt to the data and give a balanced split instead of arbitrary round amounts.
WITH t AS (
    SELECT c.customer_id, c.customer_name,
           COALESCE(SUM(o.quantity * o.unit_price * (1 - o.discount / 100)), 0) AS total
    FROM customers c
    LEFT JOIN orders o ON o.customer_id = c.customer_id AND o.order_status = 'Completed'
    GROUP BY c.customer_id, c.customer_name
),
p AS (
    SELECT PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY total) AS p75,
           PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY total) AS p25
    FROM t WHERE total > 0
)
SELECT t.customer_id, t.customer_name, ROUND(t.total, 2) AS total_spending,
       CASE WHEN t.total >= p.p75 THEN 'High Value'
            WHEN t.total >= p.p25 THEN 'Medium Value'
            ELSE 'Low Value' END AS value_band
FROM t CROSS JOIN p
ORDER BY t.total DESC;

-- Q46: Management report (top 5 customers, top 5 products, most profitable category, lowest-revenue month)
WITH sales AS (
    SELECT customer_id, product_name, product_category, order_date,
           quantity * unit_price * (1 - discount / 100) AS revenue,
           quantity * cost_price                         AS cost
    FROM orders
    WHERE order_status = 'Completed'
),
cust AS (
    SELECT 1 AS sec, 'Top 5 customers' AS section, c.customer_name AS item, SUM(s.revenue) AS value,
           ROW_NUMBER() OVER (ORDER BY SUM(s.revenue) DESC) AS rn
    FROM sales s JOIN customers c ON c.customer_id = s.customer_id
    GROUP BY c.customer_id, c.customer_name
    ORDER BY value DESC LIMIT 5
),
prod AS (
    SELECT 2, 'Top 5 products (revenue)', product_name, SUM(revenue),
           ROW_NUMBER() OVER (ORDER BY SUM(revenue) DESC)
    FROM sales
    GROUP BY product_name
    ORDER BY 4 DESC LIMIT 5
),
cat AS (
    SELECT 3, 'Most profitable category (profit)', product_category, SUM(revenue) - SUM(cost), 1::bigint
    FROM sales
    GROUP BY product_category
    ORDER BY 4 DESC LIMIT 1
),
mon AS (
    SELECT 4, 'Lowest-revenue month', TO_CHAR(DATE_TRUNC('month', order_date), 'YYYY-MM'), SUM(revenue), 1::bigint
    FROM sales
    GROUP BY DATE_TRUNC('month', order_date)
    ORDER BY 4 LIMIT 1
)
SELECT section, item, ROUND(value, 2) AS value
FROM (SELECT * FROM cust UNION ALL SELECT * FROM prod UNION ALL SELECT * FROM cat UNION ALL SELECT * FROM mon) r
ORDER BY sec, rn;

-- ============================ EXTRA: SUPPORTING QUERIES FOR insights.md ============================

-- X1: Completed orders sold below cost (insight 2)
WITH sales AS (
    SELECT product_name,
           quantity * unit_price * (1 - discount / 100) AS revenue,
           quantity * cost_price                         AS cost
    FROM orders
    WHERE order_status = 'Completed'
)
SELECT product_name, COUNT(*) AS loss_orders, ROUND(SUM(revenue - cost), 2) AS total_loss
FROM sales
WHERE revenue < cost
GROUP BY product_name
ORDER BY total_loss;

-- X2: Margin by discount band (insight 2)
WITH sales AS (
    SELECT discount,
           quantity * unit_price * (1 - discount / 100) AS revenue,
           quantity * cost_price                         AS cost
    FROM orders
    WHERE order_status = 'Completed'
)
SELECT CASE WHEN discount = 0 THEN '0%' WHEN discount <= 10 THEN '1-10%' ELSE 'over 10%' END AS discount_band,
       COUNT(*) AS orders,
       ROUND(SUM(revenue), 2) AS revenue,
       ROUND((SUM(revenue) - SUM(cost)) / NULLIF(SUM(revenue), 0) * 100, 2) AS margin_pct
FROM sales
GROUP BY 1
ORDER BY 1;

-- X3: Cancellation rate by payment method (insight 7)
SELECT payment_method, COUNT(*) AS orders,
       ROUND(100.0 * COUNT(*) FILTER (WHERE order_status = 'Cancelled') / COUNT(*), 1) AS cancelled_pct
FROM orders
GROUP BY payment_method
ORDER BY cancelled_pct DESC;
