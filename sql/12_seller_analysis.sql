-- Chapter 1 | Episode 6: Who Were the Sellers?
-- Follow-up to 05_sellers_and_states.sql; SQL Server, read-only.
-- Windows: January-August 2017 vs January-August 2018 (purchase timestamps).
-- Item sales = SUM(order_items.price), freight excluded, NO order-status filter.
-- This is not Olist's official revenue. A seller is "active" with at least one item sold in the window.
-- The sales bands (1,000 / 5,000 / 20,000) are analyst-chosen thresholds, not an Olist classification.
-- Results below were executed in SSMS by the analyst on 18 Oct 2026; each ties to the validated totals.
USE olist;
GO

-- 1. Business question: how many items did each seller sell, and for how much, in each window?
-- Result: 3,610 rows (1,227 sellers in 2017 + 2,383 in 2018);
-- item sales sum to R$ 3,113,000.32 (2017) and R$ 7,385,905.80 (2018).
SELECT
    YEAR(O.order_purchase_timestamp) AS order_year,
    I.seller_id,
    COUNT(*)     AS items_sold,
    SUM(I.price) AS item_sales
FROM order_items AS I
INNER JOIN orders AS O
    ON O.order_id = I.order_id
WHERE YEAR(O.order_purchase_timestamp) IN (2017, 2018)
  AND MONTH(O.order_purchase_timestamp) BETWEEN 1 AND 8
GROUP BY
    YEAR(O.order_purchase_timestamp),
    I.seller_id
ORDER BY order_year, item_sales DESC;

-- 2. Business question: what did the average and the median seller sell?
-- Result: 2017 -> 1,227 sellers | 3,113,000.32 | avg 2,537.08 | median 607.10
--         2018 -> 2,383 sellers | 7,385,905.80 | avg 3,099.41 | median 782.24
;WITH seller_sales AS (
    SELECT
        YEAR(O.order_purchase_timestamp) AS order_year,
        I.seller_id,
        SUM(I.price) AS item_sales
    FROM order_items AS I
    INNER JOIN orders AS O
        ON O.order_id = I.order_id
    WHERE YEAR(O.order_purchase_timestamp) IN (2017, 2018)
      AND MONTH(O.order_purchase_timestamp) BETWEEN 1 AND 8
    GROUP BY
        YEAR(O.order_purchase_timestamp),
        I.seller_id
),
medians AS (
    SELECT DISTINCT
        order_year,
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY item_sales)
            OVER (PARTITION BY order_year) AS median_sales_per_seller
    FROM seller_sales
)
SELECT
    S.order_year,
    COUNT(*) AS active_sellers,
    SUM(S.item_sales) AS total_item_sales,
    ROUND(SUM(S.item_sales) / COUNT(*), 2) AS avg_sales_per_seller,
    ROUND(M.median_sales_per_seller, 2) AS median_sales_per_seller
FROM seller_sales AS S
INNER JOIN medians AS M
    ON S.order_year = M.order_year
GROUP BY S.order_year, M.median_sales_per_seller
ORDER BY S.order_year;

-- 3. Business question: how concentrated were sales across sellers?
-- Result (sellers | item sales):
--   2017: <1,000 749 | 241,415.77 ; 1,000-4,999 322 | 730,178.10 ; 5,000-19,999 131 | 1,213,450.37 ; 20,000+ 25 | 927,956.08
--   2018: <1,000 1,323 | 453,017.86 ; 1,000-4,999 742 | 1,749,881.69 ; 5,000-19,999 255 | 2,433,967.96 ; 20,000+ 63 | 2,749,038.29
-- 20,000+: 2.6% of 2018 sellers, 37.2% of 2018 item sales (25 sellers, 29.8% of item sales in 2017).
;WITH seller_sales AS (
    SELECT
        YEAR(O.order_purchase_timestamp) AS order_year,
        I.seller_id,
        SUM(I.price) AS item_sales
    FROM order_items AS I
    INNER JOIN orders AS O
        ON O.order_id = I.order_id
    WHERE YEAR(O.order_purchase_timestamp) IN (2017, 2018)
      AND MONTH(O.order_purchase_timestamp) BETWEEN 1 AND 8
    GROUP BY
        YEAR(O.order_purchase_timestamp),
        I.seller_id
)
SELECT
    order_year,
    CASE WHEN item_sales < 1000  THEN '1: under R$ 1,000'
         WHEN item_sales < 5000  THEN '2: R$ 1,000 to 4,999'
         WHEN item_sales < 20000 THEN '3: R$ 5,000 to 19,999'
         ELSE '4: R$ 20,000 or more' END AS sales_band,
    COUNT(*) AS sellers,
    SUM(item_sales) AS item_sales
FROM seller_sales
GROUP BY
    order_year,
    CASE WHEN item_sales < 1000  THEN '1: under R$ 1,000'
         WHEN item_sales < 5000  THEN '2: R$ 1,000 to 4,999'
         WHEN item_sales < 20000 THEN '3: R$ 5,000 to 19,999'
         ELSE '4: R$ 20,000 or more' END
ORDER BY order_year, sales_band;
