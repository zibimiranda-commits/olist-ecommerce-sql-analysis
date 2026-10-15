-- Recovered/reconstructed from the analysis conversation.
-- 2017 category count recovered (a9340ff9); both-year sales and appearing categories reconstructed.
-- Prepared for SQL Server; NOT executed against SQL Server during recovery.
-- Read-only. Compare a fresh run with the recovered results before publication.
USE olist;
GO

-- Query 1: recovered 2017 category count, including its original scope.
SELECT COUNT(DISTINCT P.product_category_name) AS category_orders
FROM products AS P
INNER JOIN order_items AS I ON P.product_id = I.product_id
INNER JOIN orders AS O ON I.order_id = O.order_id
WHERE YEAR(O.order_purchase_timestamp) = 2017
  AND MONTH(O.order_purchase_timestamp) BETWEEN 1 AND 8;

-- Query 2: both-year counts (extension of the recovered query).
SELECT YEAR(O.order_purchase_timestamp) AS order_year,
       COUNT(DISTINCT P.product_category_name) AS categories_sold
FROM orders AS O
INNER JOIN order_items AS I ON O.order_id = I.order_id
INNER JOIN products AS P ON I.product_id = P.product_id
WHERE YEAR(O.order_purchase_timestamp) IN (2017, 2018)
  AND MONTH(O.order_purchase_timestamp) BETWEEN 1 AND 8
GROUP BY YEAR(O.order_purchase_timestamp);

-- Query 3: Portuguese names remain the comparison key. A LEFT JOIN keeps
-- untranslated categories, notably portateis_cozinha_e_preparadores_de_alimentos.
SELECT YEAR(O.order_purchase_timestamp) AS order_year,
       P.product_category_name,
       T.product_category_name_english,
       SUM(I.price) AS item_sales
FROM orders AS O
INNER JOIN order_items AS I ON O.order_id = I.order_id
INNER JOIN products AS P ON I.product_id = P.product_id
LEFT JOIN product_category_name_translation AS T
  ON P.product_category_name = T.product_category_name
WHERE YEAR(O.order_purchase_timestamp) IN (2017, 2018)
  AND MONTH(O.order_purchase_timestamp) BETWEEN 1 AND 8
GROUP BY YEAR(O.order_purchase_timestamp), P.product_category_name,
         T.product_category_name_english
ORDER BY order_year, item_sales DESC;

-- Query 4: categories with item rows in 2018, absent from the 2017 window.
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
