-- Recovered/reconstructed from the analysis conversation.
-- Seller/state counts recovered; conditional state sales corrected from 23b9f5f3.
-- Prepared for SQL Server; NOT executed against SQL Server during recovery.
-- Read-only. Compare a fresh run with the recovered results before publication.
USE olist;
GO

SELECT YEAR(O.order_purchase_timestamp) AS order_years,
       COUNT(DISTINCT S.seller_id) AS active_sellers,
       COUNT(DISTINCT S.seller_state) AS seller_states
FROM sellers AS S
INNER JOIN order_items AS I ON S.seller_id = I.seller_id
INNER JOIN orders AS O ON O.order_id = I.order_id
WHERE YEAR(O.order_purchase_timestamp) IN (2017, 2018)
  AND MONTH(O.order_purchase_timestamp) BETWEEN 1 AND 8
GROUP BY YEAR(O.order_purchase_timestamp);

-- Recovered state/year seller query (f8dbc05b), formatted with unchanged logic.
SELECT YEAR(O.order_purchase_timestamp) AS order_years,
       S.seller_state AS state_names,
       COUNT(DISTINCT S.seller_id) AS number_of_sellers
FROM sellers AS S
INNER JOIN order_items AS I ON S.seller_id = I.seller_id
INNER JOIN orders AS O ON O.order_id = I.order_id
WHERE YEAR(O.order_purchase_timestamp) IN (2017, 2018)
  AND MONTH(O.order_purchase_timestamp) BETWEEN 1 AND 8
GROUP BY YEAR(O.order_purchase_timestamp), S.seller_state
ORDER BY order_years, state_names;

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
