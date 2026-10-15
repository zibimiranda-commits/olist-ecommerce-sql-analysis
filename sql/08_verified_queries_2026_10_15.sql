-- Queries executed by the analyst in SSMS on 2026-10-15.
-- Outputs were copied into the project conversation; see VERIFIED_RESULTS_2026_10_15.md.
-- Read-only validation and comparison queries; no order-status filter.
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

-- 4. Appearing categories.
;WITH category_sales AS (
    SELECT YEAR(O.order_purchase_timestamp) AS order_year,
           P.product_category_name, SUM(I.price) AS item_sales
    FROM orders AS O
    INNER JOIN order_items AS I ON O.order_id = I.order_id
    INNER JOIN products AS P ON I.product_id = P.product_id
    WHERE YEAR(O.order_purchase_timestamp) IN (2017, 2018)
      AND MONTH(O.order_purchase_timestamp) BETWEEN 1 AND 8
    GROUP BY YEAR(O.order_purchase_timestamp), P.product_category_name
)
SELECT C.product_category_name, C.item_sales AS item_sales_2018,
       SUM(C.item_sales) OVER () AS appearing_category_sales
FROM category_sales AS C
WHERE C.order_year = 2018 AND C.product_category_name IS NOT NULL
  AND NOT EXISTS (
      SELECT 1 FROM category_sales AS P
      WHERE P.order_year = 2017
        AND P.product_category_name = C.product_category_name
  )
ORDER BY C.item_sales DESC;

-- 5. Disappearing categories.
SELECT DISTINCT P.product_category_name
FROM orders AS O
INNER JOIN order_items AS I ON O.order_id = I.order_id
INNER JOIN products AS P ON I.product_id = P.product_id
WHERE YEAR(O.order_purchase_timestamp) = 2017
  AND MONTH(O.order_purchase_timestamp) BETWEEN 1 AND 8
  AND P.product_category_name IS NOT NULL
EXCEPT
SELECT DISTINCT P.product_category_name
FROM orders AS O
INNER JOIN order_items AS I ON O.order_id = I.order_id
INNER JOIN products AS P ON I.product_id = P.product_id
WHERE YEAR(O.order_purchase_timestamp) = 2018
  AND MONTH(O.order_purchase_timestamp) BETWEEN 1 AND 8
  AND P.product_category_name IS NOT NULL;

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

-- 11. SP raw city labels. Observed: 151 / 228; provisional while cleaning continues.
SELECT YEAR(O.order_purchase_timestamp) AS order_year,
       COUNT(DISTINCT S.seller_city) AS seller_city_labels
FROM sellers AS S
INNER JOIN order_items AS I ON S.seller_id = I.seller_id
INNER JOIN orders AS O ON I.order_id = O.order_id
WHERE S.seller_state = 'SP'
  AND YEAR(O.order_purchase_timestamp) IN (2017, 2018)
  AND MONTH(O.order_purchase_timestamp) BETWEEN 1 AND 8
GROUP BY YEAR(O.order_purchase_timestamp)
ORDER BY order_year;
