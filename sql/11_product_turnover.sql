-- Chapter 1 | Episode 5: Were the Products the Same?
-- Follow-up to 04_buyers_and_products.sql and 10_category_contribution.sql; SQL Server, read-only.
-- Windows: January-August 2017 vs January-August 2018 (purchase timestamps).
-- Item sales = SUM(order_items.price), freight excluded, NO order-status filter.
-- This is not Olist's official revenue.
-- Results below were supplied as validated by the analyst. Queries 1 and 2 are
-- written from the structure of the validated outputs; compare them with the
-- original queries if you rerun them. Query 3 is the query executed on 17 Oct 2026.
USE olist;
GO

-- 1. Business question: how much did each product sell in each window?
-- Output: one row per product_id with revenue_2017 and revenue_2018
-- (0.00 when no sale in that window). Validated: 27,918 rows.
-- Control totals: 3,113,000.32 (2017) and 7,385,905.80 (2018).
SELECT
    I.product_id,
    SUM(CASE WHEN YEAR(O.order_purchase_timestamp) = 2017
             THEN I.price ELSE 0 END) AS revenue_2017,
    SUM(CASE WHEN YEAR(O.order_purchase_timestamp) = 2018
             THEN I.price ELSE 0 END) AS revenue_2018
FROM orders AS O
INNER JOIN order_items AS I
    ON O.order_id = I.order_id
WHERE YEAR(O.order_purchase_timestamp) IN (2017, 2018)
  AND MONTH(O.order_purchase_timestamp) BETWEEN 1 AND 8
GROUP BY I.product_id
ORDER BY I.product_id;

-- 2. Business question: were the same products sold in both windows?
-- Validated results (product_group | products | item_sales_2017 | item_sales_2018):
-- sold in both windows | 2436  | 1,068,241.11 | 1,571,855.37
-- sold in 2018 only    | 18059 |         0.00 | 5,814,050.43
-- sold in 2017 only    | 7423  | 2,044,759.21 |         0.00
-- Products: 2,436 + 18,059 + 7,423 = 27,918. "No sale in a window" does not
-- mean the product is new or discontinued.
;WITH product_sales AS (
    SELECT
        I.product_id,
        SUM(CASE WHEN YEAR(O.order_purchase_timestamp) = 2017
                 THEN I.price ELSE 0 END) AS revenue_2017,
        SUM(CASE WHEN YEAR(O.order_purchase_timestamp) = 2018
                 THEN I.price ELSE 0 END) AS revenue_2018
    FROM orders AS O
    INNER JOIN order_items AS I
        ON O.order_id = I.order_id
    WHERE YEAR(O.order_purchase_timestamp) IN (2017, 2018)
      AND MONTH(O.order_purchase_timestamp) BETWEEN 1 AND 8
    GROUP BY I.product_id
)
SELECT
    CASE WHEN revenue_2017 > 0 AND revenue_2018 > 0 THEN 'sold in both windows'
         WHEN revenue_2018 > 0 THEN 'sold in 2018 only'
         ELSE 'sold in 2017 only' END AS product_group,
    COUNT(*) AS products,
    SUM(revenue_2017) AS item_sales_2017,
    SUM(revenue_2018) AS item_sales_2018
FROM product_sales
GROUP BY
    CASE WHEN revenue_2017 > 0 AND revenue_2018 > 0 THEN 'sold in both windows'
         WHEN revenue_2018 > 0 THEN 'sold in 2018 only'
         ELSE 'sold in 2017 only' END;

-- 3. Business question: did the products sold in January-August 2018 have an
-- earlier recorded sale anywhere in the dataset (before 1 January 2018)?
-- Validated results (product_history | products | item_sales_2018):
-- no sale before 2018 | 15500 | 4,490,754.07
-- sold before 2018    |  4995 | 2,895,151.73
-- Totals: 20,495 products and 7,385,905.80 (matches the 2018 window).
-- Limit: "no recorded sale before 2018" is not proof that a product is new;
-- the dataset's history is limited and product identifiers may change.
;WITH sales_2018 AS (
    SELECT
        I.product_id,
        SUM(I.price) AS revenue_2018
    FROM orders AS O
    INNER JOIN order_items AS I
        ON O.order_id = I.order_id
    WHERE YEAR(O.order_purchase_timestamp) = 2018
      AND MONTH(O.order_purchase_timestamp) BETWEEN 1 AND 8
    GROUP BY I.product_id
),
sold_before_2018 AS (
    SELECT DISTINCT I.product_id
    FROM orders AS O
    INNER JOIN order_items AS I
        ON O.order_id = I.order_id
    WHERE O.order_purchase_timestamp < '2018-01-01'
)
SELECT
    CASE WHEN B.product_id IS NOT NULL
         THEN 'sold before 2018'
         ELSE 'no sale before 2018' END AS product_history,
    COUNT(*) AS products,
    SUM(S.revenue_2018) AS item_sales_2018
FROM sales_2018 AS S
LEFT JOIN sold_before_2018 AS B
    ON S.product_id = B.product_id
GROUP BY
    CASE WHEN B.product_id IS NOT NULL
         THEN 'sold before 2018'
         ELSE 'no sale before 2018' END;
