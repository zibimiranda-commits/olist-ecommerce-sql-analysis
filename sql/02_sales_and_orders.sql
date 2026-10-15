-- Olist: three separate queries supplied by the project author.
-- Query logic preserved as supplied. No order-status filter; freight excluded.
-- MIT License; see LICENSE in the repository.

-- 1. Number of orders.
SELECT YEAR(order_purchase_timestamp) AS order_year,
       COUNT(DISTINCT order_id) AS total_orders
FROM orders
WHERE YEAR(order_purchase_timestamp) IN (2017, 2018)
  AND MONTH(order_purchase_timestamp) BETWEEN 1 AND 8
GROUP BY YEAR(order_purchase_timestamp)
ORDER BY order_year;

-- 2. Item sales.
SELECT YEAR(O.order_purchase_timestamp) AS order_year,
       SUM(I.price) AS item_sales
FROM orders AS O
INNER JOIN order_items AS I ON O.order_id = I.order_id
WHERE YEAR(O.order_purchase_timestamp) IN (2017, 2018)
  AND MONTH(O.order_purchase_timestamp) BETWEEN 1 AND 8
GROUP BY YEAR(O.order_purchase_timestamp)
ORDER BY order_year;

-- 3. Item sales per recorded order.
SELECT
    YEAR(O.order_purchase_timestamp) AS order_year,
    ROUND(
        SUM(I.price) / COUNT(DISTINCT O.order_id), 2
    ) AS item_sales_per_order
FROM orders AS O
LEFT JOIN order_items AS I
    ON O.order_id = I.order_id
WHERE YEAR(O.order_purchase_timestamp) IN (2017, 2018)
    AND MONTH(O.order_purchase_timestamp) BETWEEN 1 AND 8
GROUP BY YEAR(O.order_purchase_timestamp)
ORDER BY order_year;
