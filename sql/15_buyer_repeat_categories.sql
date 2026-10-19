-- Chapter 1 | Episode 9: Did Buyers Come Back?
-- Follow-up to 09_buyer_repeat_purchasing.sql; SQL Server, read-only. No data is modified.
-- Windows: January-August 2017 vs January-August 2018 (purchase timestamps). Buyers = customer_unique_id.
-- NO order-status filter. Item sales = SUM(order_items.price), freight excluded; not Olist's official revenue.
-- "Everyday-use" is the analyst's own grouping of 8 categories (beleza_saude, perfumaria, alimentos_bebidas,
-- alimentos, bebidas, bebes, fraldas_higiene, pet_shop); it is not an Olist classification.
-- Queries 1-3 results were executed in SSMS by the analyst on 19 Oct 2026 and match the figures in the posts.
USE olist;
GO

-- 1. Buyers who placed a single order (Jan-Aug of each year)
-- Result: 2017 | 22,320 buyers | 21,733 single-order | 97.4%   2018 | 52,743 | 51,586 | 97.8%
;WITH buyer_orders AS (
    SELECT
        YEAR(O.order_purchase_timestamp) AS purchase_year,
        C.customer_unique_id,
        COUNT(DISTINCT O.order_id) AS orders
    FROM orders AS O
    INNER JOIN customers AS C
        ON C.customer_id = O.customer_id
    WHERE YEAR(O.order_purchase_timestamp) IN (2017, 2018)
      AND MONTH(O.order_purchase_timestamp) BETWEEN 1 AND 8
    GROUP BY YEAR(O.order_purchase_timestamp), C.customer_unique_id
)
SELECT
    purchase_year,
    COUNT(*) AS buyers,
    SUM(CASE WHEN orders = 1 THEN 1 ELSE 0 END) AS single_order_buyers,
    CAST(100.0 * SUM(CASE WHEN orders = 1 THEN 1 ELSE 0 END) / COUNT(*) AS DECIMAL(5,1)) AS pct_single_order
FROM buyer_orders
GROUP BY purchase_year
ORDER BY purchase_year;

-- 2. Everyday-use categories vs other: item sales and buyers with 2+ orders in the SAME group
-- Result (buyers | with 2+ orders | % | item sales):
--   2017 everyday-use 3,563 | 69 | 1.94 | 499,901.04    2017 other 18,589 | 472 | 2.54 | 2,613,099.28
--   2018 everyday-use 10,143 | 111 | 1.09 | 1,383,133.74  2018 other 42,664 | 886 | 2.08 | 6,002,772.06
-- Sales tie to the totals (3,113,000.32 and 7,385,905.80); everyday-use share = 16.1% and 18.7%.
-- A buyer can appear in both groups, so group buyer counts do not add up to the overall buyer count.
;WITH buyer_group_orders AS (
    SELECT
        YEAR(O.order_purchase_timestamp) AS purchase_year,
        C.customer_unique_id,
        CASE WHEN P.product_category_name IN ('beleza_saude','perfumaria','alimentos_bebidas',
                                              'alimentos','bebidas','bebes','fraldas_higiene','pet_shop')
             THEN 'everyday-use' ELSE 'other' END AS category_group,
        COUNT(DISTINCT O.order_id) AS orders,
        SUM(I.price) AS item_sales
    FROM order_items AS I
    INNER JOIN orders AS O
        ON O.order_id = I.order_id
    INNER JOIN customers AS C
        ON C.customer_id = O.customer_id
    LEFT JOIN products AS P
        ON P.product_id = I.product_id
    WHERE YEAR(O.order_purchase_timestamp) IN (2017, 2018)
      AND MONTH(O.order_purchase_timestamp) BETWEEN 1 AND 8
    GROUP BY
        YEAR(O.order_purchase_timestamp),
        C.customer_unique_id,
        CASE WHEN P.product_category_name IN ('beleza_saude','perfumaria','alimentos_bebidas',
                                              'alimentos','bebidas','bebes','fraldas_higiene','pet_shop')
             THEN 'everyday-use' ELSE 'other' END
)
SELECT
    purchase_year,
    category_group,
    COUNT(*) AS buyers,
    SUM(CASE WHEN orders >= 2 THEN 1 ELSE 0 END) AS buyers_2plus,
    CAST(100.0 * SUM(CASE WHEN orders >= 2 THEN 1 ELSE 0 END) / COUNT(*) AS DECIMAL(5,2)) AS pct_2plus,
    SUM(item_sales) AS item_sales
FROM buyer_group_orders
GROUP BY purchase_year, category_group
ORDER BY purchase_year, category_group;

-- 3. Follow-up of buyers whose first recorded order was in Jan-Mar 2017
-- Result: 5,152 buyers whose first recorded order was in Jan-Mar 2017 | 261 ordered again | 5.07%
-- Orders are counted over the whole dataset, not only the eight-month window.
;WITH buyer_history AS (
    SELECT
        C.customer_unique_id,
        MIN(O.order_purchase_timestamp) AS first_order,
        COUNT(DISTINCT O.order_id) AS orders_total
    FROM orders AS O
    INNER JOIN customers AS C
        ON C.customer_id = O.customer_id
    GROUP BY C.customer_unique_id
)
SELECT
    COUNT(*) AS cohort_buyers,
    SUM(CASE WHEN orders_total >= 2 THEN 1 ELSE 0 END) AS ordered_again,
    CAST(100.0 * SUM(CASE WHEN orders_total >= 2 THEN 1 ELSE 0 END) / COUNT(*) AS DECIMAL(5,2)) AS pct_ordered_again
FROM buyer_history
WHERE first_order >= '2017-01-01'
  AND first_order <  '2017-04-01';
