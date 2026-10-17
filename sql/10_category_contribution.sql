-- Chapter 1 | Episode 4: Which Categories Contributed Most to the Increase?
-- Follow-up to 03_categories.sql; SQL Server, read-only.
-- Windows: January-August 2017 vs January-August 2018 (purchase timestamps).
-- Item sales = SUM(order_items.price), freight excluded, NO order-status filter.
-- This is not Olist's official revenue.
-- Results shown in the Episode 4 images were derived from the validated
-- per-category totals (query 1, 2017 and 2018); query 2 itself is to be rerun
-- in SSMS and checked against the control total.
USE olist;
GO

-- 1. Business question: how much did each category sell in each window?
-- Run once with 2017 and once with 2018 (change the year below).
-- Control totals: 3,113,000.32 (2017) and 7,385,905.80 (2018).
-- Note: 'pc_gamer' and 'portateis_cozinha_e_preparadores_de_alimentos' have no
-- English translation; some English names carry trailing spaces (hence RTRIM).
SELECT YEAR(O.order_purchase_timestamp) AS order_year,
       P.product_category_name AS category_pt,
       RTRIM(T.product_category_name_english) AS category_en,
       SUM(I.price) AS revenue
FROM orders AS O
INNER JOIN order_items AS I ON O.order_id = I.order_id
INNER JOIN products AS P ON P.product_id = I.product_id
LEFT JOIN product_category_name_translation AS T
       ON P.product_category_name = T.product_category_name
WHERE YEAR(O.order_purchase_timestamp) = 2017
  AND MONTH(O.order_purchase_timestamp) BETWEEN 1 AND 8
GROUP BY P.product_category_name, T.product_category_name_english,
         YEAR(O.order_purchase_timestamp)
ORDER BY order_year, category_pt;

-- 2. Business question: which categories contributed most to the increase?
-- Contribution = sales 2018 - sales 2017. It mixes category size and growth
-- speed; it does not establish causes.
-- Control: the sum of all increases must equal 4,272,905.48.
-- Expected top three (from the category tables): beleza_saude,
-- relogios_presentes, esporte_lazer.
;WITH category_sales AS (
    SELECT P.product_category_name AS category_pt,
           SUM(CASE WHEN YEAR(O.order_purchase_timestamp) = 2017 THEN I.price ELSE 0 END) AS sales_2017,
           SUM(CASE WHEN YEAR(O.order_purchase_timestamp) = 2018 THEN I.price ELSE 0 END) AS sales_2018
    FROM orders AS O
    INNER JOIN order_items AS I ON O.order_id = I.order_id
    INNER JOIN products AS P ON P.product_id = I.product_id
    WHERE YEAR(O.order_purchase_timestamp) IN (2017, 2018)
      AND MONTH(O.order_purchase_timestamp) BETWEEN 1 AND 8
    GROUP BY P.product_category_name
)
SELECT TOP 10
       category_pt,
       sales_2017,
       sales_2018,
       sales_2018 - sales_2017 AS increase,
       ROUND(100.0 * (sales_2018 - sales_2017)
             / (SELECT SUM(sales_2018 - sales_2017) FROM category_sales), 2) AS pct_of_increase
FROM category_sales
ORDER BY increase DESC;

-- 3. Business question: did categories absent in one window explain the growth?
-- Validated: three categories appear in 2018 with no 2017 sale
-- (R$ 6,164.76, about 0.14% of the increase); seguros_e_servicos has no
-- 2018 sale. See VERIFIED_RESULTS_2026_10_15.md, section 3.
SELECT DISTINCT P.product_category_name
FROM orders AS O
INNER JOIN order_items AS I ON O.order_id = I.order_id
INNER JOIN products AS P ON P.product_id = I.product_id
WHERE YEAR(O.order_purchase_timestamp) = 2018
  AND MONTH(O.order_purchase_timestamp) BETWEEN 1 AND 8
EXCEPT
SELECT DISTINCT P.product_category_name
FROM orders AS O
INNER JOIN order_items AS I ON O.order_id = I.order_id
INNER JOIN products AS P ON P.product_id = I.product_id
WHERE YEAR(O.order_purchase_timestamp) = 2017
  AND MONTH(O.order_purchase_timestamp) BETWEEN 1 AND 8;
