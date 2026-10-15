-- Recovered/reconstructed from the analysis conversation.
-- Buyer query corrected from 565c87bf (removed stray comma); product counts/details reconstructed.
-- Prepared for SQL Server; NOT executed against SQL Server during recovery.
-- Read-only. Compare a fresh run with the recovered results before publication.
USE olist;
GO

SELECT YEAR(O.order_purchase_timestamp) AS orders_year,
       COUNT(DISTINCT C.customer_unique_id) AS numbers_buyers
FROM customers AS C
INNER JOIN orders AS O ON C.customer_id = O.customer_id
WHERE YEAR(O.order_purchase_timestamp) IN (2017, 2018)
  AND MONTH(O.order_purchase_timestamp) BETWEEN 1 AND 8
GROUP BY YEAR(O.order_purchase_timestamp)
ORDER BY orders_year;

SELECT YEAR(O.order_purchase_timestamp) AS order_year,
       COUNT(DISTINCT I.product_id) AS sold_product_references
FROM orders AS O
INNER JOIN order_items AS I ON O.order_id = I.order_id
WHERE YEAR(O.order_purchase_timestamp) IN (2017, 2018)
  AND MONTH(O.order_purchase_timestamp) BETWEEN 1 AND 8
GROUP BY YEAR(O.order_purchase_timestamp);

-- Reconstructed detailed product comparison; its original full output is not recovered.
SELECT I.product_id,
       SUM(CASE WHEN YEAR(O.order_purchase_timestamp) = 2017 THEN I.price ELSE 0 END) AS item_sales_2017,
       SUM(CASE WHEN YEAR(O.order_purchase_timestamp) = 2018 THEN I.price ELSE 0 END) AS item_sales_2018
FROM orders AS O
INNER JOIN order_items AS I ON O.order_id = I.order_id
INNER JOIN products AS P ON I.product_id = P.product_id
WHERE YEAR(O.order_purchase_timestamp) IN (2017, 2018)
  AND MONTH(O.order_purchase_timestamp) BETWEEN 1 AND 8
GROUP BY I.product_id
ORDER BY I.product_id;
