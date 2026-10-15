-- Separate queries used and rerun by the analyst in SSMS on 2026-10-15.
-- Formatting consolidated for the repository; no combined CTE is introduced.
-- Read-only; no order-status filter. See VERIFIED_RESULTS_2026_10_15.md.
USE olist;
GO

-- 6. Unique buyers.
SELECT YEAR(O.order_purchase_timestamp) AS order_year,
       COUNT(DISTINCT C.customer_unique_id) AS unique_buyers
FROM customers AS C
INNER JOIN orders AS O ON C.customer_id = O.customer_id
WHERE YEAR(O.order_purchase_timestamp) IN (2017, 2018)
  AND MONTH(O.order_purchase_timestamp) BETWEEN 1 AND 8
GROUP BY YEAR(O.order_purchase_timestamp)
ORDER BY order_year;

-- 7. Sold product references.
SELECT YEAR(O.order_purchase_timestamp) AS order_year,
       COUNT(DISTINCT I.product_id) AS sold_product_references
FROM orders AS O
INNER JOIN order_items AS I ON O.order_id = I.order_id
WHERE YEAR(O.order_purchase_timestamp) IN (2017, 2018)
  AND MONTH(O.order_purchase_timestamp) BETWEEN 1 AND 8
GROUP BY YEAR(O.order_purchase_timestamp)
ORDER BY order_year;
