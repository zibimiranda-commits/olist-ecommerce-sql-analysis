-- Recovered/reconstructed from the analysis conversation.
-- Order count recovered (61445624); period sales reconstructed from joins and recorded definitions.
-- Prepared for SQL Server; NOT executed against SQL Server during recovery.
-- Read-only. Compare a fresh run with the recovered results before publication.
USE olist;
GO

-- Query 1: original COUNT(order_id) logic, not COUNT(DISTINCT order_id).
-- The equivalence to distinct orders requires unique, non-null order IDs.
SELECT YEAR(order_purchase_timestamp) AS year_orders,
       COUNT(order_id) AS numbers_id
FROM orders
WHERE YEAR(order_purchase_timestamp) IN (2017, 2018)
  AND MONTH(order_purchase_timestamp) BETWEEN 1 AND 8
GROUP BY YEAR(order_purchase_timestamp);

-- Query 2: sum item prices; no order-status filter, no freight.
SELECT YEAR(O.order_purchase_timestamp) AS order_year,
       SUM(I.price) AS item_sales
FROM orders AS O
INNER JOIN order_items AS I ON O.order_id = I.order_id
WHERE YEAR(O.order_purchase_timestamp) IN (2017, 2018)
  AND MONTH(O.order_purchase_timestamp) BETWEEN 1 AND 8
GROUP BY YEAR(O.order_purchase_timestamp)
ORDER BY order_year;
