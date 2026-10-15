-- Separate queries used and rerun by the analyst in SSMS on 2026-10-15.
-- Formatting consolidated for the repository; no combined CTE is introduced.
-- Read-only; no order-status filter. See VERIFIED_RESULTS_2026_10_15.md.
USE olist;
GO

-- 3. Category counts.
SELECT YEAR(O.order_purchase_timestamp) AS order_year,
       COUNT(DISTINCT P.product_category_name) AS categories_sold
FROM orders AS O
INNER JOIN order_items AS I ON O.order_id = I.order_id
INNER JOIN products AS P ON I.product_id = P.product_id
WHERE YEAR(O.order_purchase_timestamp) IN (2017, 2018)
  AND MONTH(O.order_purchase_timestamp) BETWEEN 1 AND 8
GROUP BY YEAR(O.order_purchase_timestamp)
ORDER BY order_year;

-- The appearing-category subtotal and disappearing category were checked
-- separately in a guided validation session. Their outputs remain recorded
-- in VERIFIED_RESULTS_2026_10_15.md. The main script here retains the simple
-- category count; it does not add a WITH/CTE or window-function calculation.
-- The historical assisted verification is preserved in script 08, not presented
-- as the original independent analysis workflow.
