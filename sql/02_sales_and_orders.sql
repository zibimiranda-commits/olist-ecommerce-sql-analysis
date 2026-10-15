-- Separate queries used and rerun by the analyst in SSMS on 2026-10-15.
-- Formatting consolidated for the repository; no combined CTE is introduced.
-- Read-only; no order-status filter. See VERIFIED_RESULTS_2026_10_15.md.
USE olist;
GO

-- 1. Check order IDs.
SELECT COUNT(*) AS total_rows, COUNT(order_id) AS non_null_order_ids,
       COUNT(DISTINCT order_id) AS distinct_order_ids
FROM orders;

-- 2. Orders and item sales by period.
SELECT YEAR(order_purchase_timestamp) AS order_year,
       COUNT(DISTINCT order_id) AS total_orders
FROM orders
WHERE YEAR(order_purchase_timestamp) IN (2017, 2018)
  AND MONTH(order_purchase_timestamp) BETWEEN 1 AND 8
GROUP BY YEAR(order_purchase_timestamp)
ORDER BY order_year;

SELECT YEAR(O.order_purchase_timestamp) AS order_year, SUM(I.price) AS item_sales
FROM orders AS O
INNER JOIN order_items AS I ON O.order_id = I.order_id
WHERE YEAR(O.order_purchase_timestamp) IN (2017, 2018)
  AND MONTH(O.order_purchase_timestamp) BETWEEN 1 AND 8
GROUP BY YEAR(O.order_purchase_timestamp)
ORDER BY order_year;

-- Item sales per recorded order were obtained by dividing the two outputs.
-- 2017: 3,113,000.32 / 22,968 = 135.54 (rounded).
-- 2018: 7,385,905.80 / 53,991 = 136.80 (rounded).
-- This file intentionally keeps the order and sales queries separate.
