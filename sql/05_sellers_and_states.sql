-- Separate queries used and rerun by the analyst in SSMS on 2026-10-15.
-- Formatting consolidated for the repository; no combined CTE is introduced.
-- Read-only; no order-status filter. See VERIFIED_RESULTS_2026_10_15.md.
USE olist;
GO

-- 8. Active sellers and represented states.
SELECT YEAR(O.order_purchase_timestamp) AS order_year,
       COUNT(DISTINCT S.seller_id) AS active_sellers,
       COUNT(DISTINCT S.seller_state) AS seller_states
FROM sellers AS S
INNER JOIN order_items AS I ON S.seller_id = I.seller_id
INNER JOIN orders AS O ON I.order_id = O.order_id
WHERE YEAR(O.order_purchase_timestamp) IN (2017, 2018)
  AND MONTH(O.order_purchase_timestamp) BETWEEN 1 AND 8
GROUP BY YEAR(O.order_purchase_timestamp)
ORDER BY order_year;

-- 9. Active sellers by state, side by side.
SELECT S.seller_state,
       COUNT(DISTINCT CASE WHEN YEAR(O.order_purchase_timestamp) = 2017 THEN S.seller_id END) AS sellers_2017,
       COUNT(DISTINCT CASE WHEN YEAR(O.order_purchase_timestamp) = 2018 THEN S.seller_id END) AS sellers_2018
FROM sellers AS S
INNER JOIN order_items AS I ON S.seller_id = I.seller_id
INNER JOIN orders AS O ON I.order_id = O.order_id
WHERE YEAR(O.order_purchase_timestamp) IN (2017, 2018)
  AND MONTH(O.order_purchase_timestamp) BETWEEN 1 AND 8
GROUP BY S.seller_state
ORDER BY S.seller_state;

-- 10. Item sales by recorded seller state.
SELECT S.seller_state,
       SUM(CASE WHEN YEAR(O.order_purchase_timestamp) = 2017 THEN I.price ELSE 0 END) AS item_sales_2017,
       SUM(CASE WHEN YEAR(O.order_purchase_timestamp) = 2018 THEN I.price ELSE 0 END) AS item_sales_2018
FROM orders AS O
INNER JOIN order_items AS I ON O.order_id = I.order_id
INNER JOIN sellers AS S ON I.seller_id = S.seller_id
WHERE YEAR(O.order_purchase_timestamp) IN (2017, 2018)
  AND MONTH(O.order_purchase_timestamp) BETWEEN 1 AND 8
GROUP BY S.seller_state
ORDER BY S.seller_state;
