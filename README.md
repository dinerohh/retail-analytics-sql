# Retail Sales and Customer Intelligence with PostgreSQL

A SQL analysis of **Duka Smart Electronics**, a fictional Kenyan electronics retailer trading in ten towns since January 2025. The project builds the database, loads 150 customers and 800 orders, answers 46 business questions in SQL, and turns the results into management insights.

All people and companies in the data are fictional.

## What is in this repository

| File | Purpose |
|---|---|
| `schema.sql` | Table definitions: primary keys, a foreign key, CHECK constraints and indexes |
| `queries.sql` | Answers to all 46 questions (`-- Q1` to `-- Q46`), plus three supporting queries (`-- X1` to `-- X3`) |
| `insights.md` | Eight business insights, each with the finding, why it matters and a recommendation |
| `screenshots/` | Verification output and selected query results |

The data files (`03_insert_customers.sql`, `04_insert_orders.sql`) come from the project page and are not included here.

## Requirements

- PostgreSQL 14 or newer (includes `psql` and pgAdmin)
- The project data scripts: `03_insert_customers.sql` and `04_insert_orders.sql`

## Setup

Run each command from the folder that holds the files. Use the password you set for the `postgres` user.

```bash
# 1. Create the database (connected to the default postgres database)
psql -U postgres -d postgres -c "CREATE DATABASE retail_analytics;"

# 2. Create the tables
psql -U postgres -d retail_analytics -f schema.sql

# 3. Load the data (customers first, because orders reference them)
psql -U postgres -d retail_analytics -f 03_insert_customers.sql
psql -U postgres -d retail_analytics -f 04_insert_orders.sql

# 4. Check the load (expect 150 customers, 800 orders, 0 orders with no customer)
psql -U postgres -d retail_analytics -f 05_verify_data.sql
```

pgAdmin users: create the `retail_analytics` database from the menu (Databases, Create, Database), open the Query Tool on it, and run `schema.sql`, then the two data scripts.

## Running the queries

```bash
psql -U postgres -d retail_analytics -f queries.sql
```

This prints the result of every query in order. To run a single question, open `queries.sql` in pgAdmin or DBeaver and execute just that block.

Every query reads directly from `customers` and `orders`. `queries.sql` also creates the `monthly_sales_summary` view (Q43) and the `customer_revenue` function (Q44). Both use `CREATE OR REPLACE`, so the file is safe to run more than once.

## Business rules applied

1. **Revenue** is `quantity * unit_price * (1 - discount / 100)`, cost is `quantity * cost_price`, and profit is revenue minus cost.
2. **Money questions** (revenue, cost, profit, spending, averages) use Completed orders only, so each such query filters on `order_status = 'Completed'`.
3. **Order counts** include every order, whatever its status.
4. **Customer counts** use distinct customers.
5. **"Today"** is the latest `order_date` in the data (30 September 2026), not the computer's date.
6. **Months** mean year and month, using `DATE_TRUNC('month', order_date)`.
7. Money is rounded to 2 decimal places.

## Definitions chosen where a question was open

- **Q18, quantity sold:** units on Completed orders.
- **Q27, average customer spending by segment:** each purchasing customer's completed total first, then the average of those totals per segment.
- **Q28, most popular category for VIP customers:** the number of completed orders, with units as the tie-breaker.
- **Q30, average unit price:** averaged over all order rows.
- **Q43, orders column:** every order in the month, while revenue, cost and profit use Completed orders.
- **Q45, value bands:** High is the top 25 percent of buying customers by spending, Low is the bottom 25 percent or customers with no completed orders, and Medium is the rest. Percentiles adapt to the data and give a balanced split.

## Headline results

- Completed revenue: KSh 24,155,372. Profit: KSh 2,890,922 (about 12 percent margin).
- Accessories are 4.5 percent of revenue but 15.8 percent of profit, with a 42 percent margin.
- 62 completed orders were sold below cost, losing KSh 141,979, mostly through discounts on refrigerators, phones, laptops and TVs.
- 47 of 132 buying customers have not ordered in over 90 days and hold 19 percent of lifetime revenue.
- Revenue for January to September 2026 is 86 percent higher than the same months of 2025.

See `insights.md` for all eight insights with recommendations.
