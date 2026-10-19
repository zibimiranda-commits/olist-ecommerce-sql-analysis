-- Chapter 1 | Episode 7: Were the Sellers the Same?
-- Follow-up to 12_seller_analysis.sql; SQL Server, read-only.
-- Windows: January-August 2017 vs January-August 2018 (purchase timestamps).
-- Item sales = SUM(order_items.price), freight excluded, NO order-status filter.
-- This is not Olist's official revenue. An active seller has at least one recorded order item in the window.
-- Activity is tested with item sales > 0 in the window. This matches "at least one order item": the groups give
-- 686 + 541 = 1,227 and 686 + 1,697 = 2,383 sellers, the same counts as the item-row based counts in 12_seller_analysis.sql.
-- "No sale before 2018" = no order item before 1 Jan 2018 in this dataset; it does not establish that a seller is new.
-- The sales bands (1,000 / 5,000 / 20,000) are analyst-chosen thresholds, not an Olist classification.
-- Queries 1-3 results were executed in SSMS by the analyst on 18 Oct 2026 and tie to the validated totals.
USE olist;
GO

-- 1. Business question: were the sellers active in 2018 also active in 2017?
-- Result: active in 2017 only 541 | 535,266.97 | 0.00
--         active in 2018 only 1,697 | 0.00 | 3,712,925.27
--         active in both windows 686 | 2,577,733.35 | 3,672,980.53
-- Totals: 2,924 distinct sellers; sales 3,113,000.32 (2017) and 7,385,905.80 (2018).
;WITH seller_windows AS (
    SELECT
        I.seller_id,
        SUM(CASE WHEN YEAR(O.order_purchase_timestamp) = 2017
                 THEN I.price ELSE 0 END) AS sales_2017,
        SUM(CASE WHEN YEAR(O.order_purchase_timestamp) = 2018
                 THEN I.price ELSE 0 END) AS sales_2018
    FROM order_items AS I
    INNER JOIN orders AS O
        ON O.order_id = I.order_id
    WHERE YEAR(O.order_purchase_timestamp) IN (2017, 2018)
      AND MONTH(O.order_purchase_timestamp) BETWEEN 1 AND 8
    GROUP BY I.seller_id
)
SELECT
    CASE WHEN sales_2017 > 0 AND sales_2018 > 0 THEN 'active in both windows'
         WHEN sales_2018 > 0 THEN 'active in 2018 only'
         ELSE 'active in 2017 only' END AS seller_group,
    COUNT(*) AS sellers,
    SUM(sales_2017) AS item_sales_2017,
    SUM(sales_2018) AS item_sales_2018
FROM seller_windows
GROUP BY
    CASE WHEN sales_2017 > 0 AND sales_2018 > 0 THEN 'active in both windows'
         WHEN sales_2018 > 0 THEN 'active in 2018 only'
         ELSE 'active in 2017 only' END;

-- 2. Business question: did the sellers active in 2018 have a recorded sale before 2018?
-- Result: no sale before 2018 1,284 | 2,214,796.80 ; sold before 2018 1,099 | 5,171,109.00
-- Totals: 2,383 sellers and 7,385,905.80 (53.9% of sellers, 30.0% of item sales have no sale before 2018).
-- The 1,099 include the 686 active in both windows plus 413 who sold before 2018 but not in Jan-Aug 2017.
;WITH sales_2018 AS (
    SELECT
        I.seller_id,
        SUM(I.price) AS item_sales_2018
    FROM order_items AS I
    INNER JOIN orders AS O
        ON O.order_id = I.order_id
    WHERE YEAR(O.order_purchase_timestamp) = 2018
      AND MONTH(O.order_purchase_timestamp) BETWEEN 1 AND 8
    GROUP BY I.seller_id
),
sold_before_2018 AS (
    SELECT DISTINCT I.seller_id
    FROM order_items AS I
    INNER JOIN orders AS O
        ON O.order_id = I.order_id
    WHERE O.order_purchase_timestamp < '2018-01-01'
)
SELECT
    CASE WHEN B.seller_id IS NOT NULL
         THEN 'sold before 2018'
         ELSE 'no sale before 2018' END AS seller_history,
    COUNT(*) AS sellers,
    SUM(S.item_sales_2018) AS item_sales_2018
FROM sales_2018 AS S
LEFT JOIN sold_before_2018 AS B
    ON S.seller_id = B.seller_id
GROUP BY
    CASE WHEN B.seller_id IS NOT NULL
         THEN 'sold before 2018'
         ELSE 'no sale before 2018' END;

-- 3. Business question: which 2017 sellers were active again in 2018, by 2017 sales band?
-- Result (sellers_2017 | also_active_2018 | not_active_2018):
--   under 1,000: 749 | 323 | 426 ; 1,000-4,999: 322 | 228 | 94 ; 5,000-19,999: 131 | 112 | 19 ; 20,000+: 25 | 23 | 2
-- Totals: 1,227 sellers, 686 active again, 541 not (43.1% / 70.8% / 85.5% / 92.0% active again by band).
;WITH seller_windows AS (
    SELECT
        I.seller_id,
        SUM(CASE WHEN YEAR(O.order_purchase_timestamp) = 2017
                 THEN I.price ELSE 0 END) AS sales_2017,
        SUM(CASE WHEN YEAR(O.order_purchase_timestamp) = 2018
                 THEN I.price ELSE 0 END) AS sales_2018
    FROM order_items AS I
    INNER JOIN orders AS O
        ON O.order_id = I.order_id
    WHERE YEAR(O.order_purchase_timestamp) IN (2017, 2018)
      AND MONTH(O.order_purchase_timestamp) BETWEEN 1 AND 8
    GROUP BY I.seller_id
)
SELECT
    CASE WHEN sales_2017 < 1000  THEN '1: under R$ 1,000'
         WHEN sales_2017 < 5000  THEN '2: R$ 1,000 to 4,999'
         WHEN sales_2017 < 20000 THEN '3: R$ 5,000 to 19,999'
         ELSE '4: R$ 20,000 or more' END AS band_2017,
    COUNT(*) AS sellers_2017,
    SUM(CASE WHEN sales_2018 > 0 THEN 1 ELSE 0 END) AS also_active_2018,
    SUM(CASE WHEN sales_2018 = 0 THEN 1 ELSE 0 END) AS not_active_2018
FROM seller_windows
WHERE sales_2017 > 0
GROUP BY
    CASE WHEN sales_2017 < 1000  THEN '1: under R$ 1,000'
         WHEN sales_2017 < 5000  THEN '2: R$ 1,000 to 4,999'
         WHEN sales_2017 < 20000 THEN '3: R$ 5,000 to 19,999'
         ELSE '4: R$ 20,000 or more' END
ORDER BY band_2017;

-- 4. Supporting check (not shown in the post): band movement of the sellers active in both windows.
-- Executed in SSMS on 18 Oct 2026. NULL means the seller had no sale in that window.
-- Of the 686: 214 moved to a higher band, 339 stayed in the same band, 133 moved to a lower band.
-- Top band 2018 (63 sellers): 33 from the 686 and 30 active in 2018 only.
;WITH seller_windows AS (
    SELECT
        I.seller_id,
        SUM(CASE WHEN YEAR(O.order_purchase_timestamp) = 2017
                 THEN I.price ELSE 0 END) AS sales_2017,
        SUM(CASE WHEN YEAR(O.order_purchase_timestamp) = 2018
                 THEN I.price ELSE 0 END) AS sales_2018
    FROM order_items AS I
    INNER JOIN orders AS O
        ON O.order_id = I.order_id
    WHERE YEAR(O.order_purchase_timestamp) IN (2017, 2018)
      AND MONTH(O.order_purchase_timestamp) BETWEEN 1 AND 8
    GROUP BY I.seller_id
),
banded AS (
    SELECT
        CASE WHEN sales_2017 > 0 AND sales_2018 > 0 THEN 'active in both windows'
         WHEN sales_2018 > 0 THEN 'active in 2018 only'
         ELSE 'active in 2017 only' END AS seller_group,
        sales_2017,
        sales_2018,
        CASE WHEN sales_2017 = 0     THEN NULL
         WHEN sales_2017 < 1000  THEN '1: under R$ 1,000'
         WHEN sales_2017 < 5000  THEN '2: R$ 1,000 to 4,999'
         WHEN sales_2017 < 20000 THEN '3: R$ 5,000 to 19,999'
         ELSE '4: R$ 20,000 or more' END AS band_2017,
        CASE WHEN sales_2018 = 0     THEN NULL
         WHEN sales_2018 < 1000  THEN '1: under R$ 1,000'
         WHEN sales_2018 < 5000  THEN '2: R$ 1,000 to 4,999'
         WHEN sales_2018 < 20000 THEN '3: R$ 5,000 to 19,999'
         ELSE '4: R$ 20,000 or more' END AS band_2018
    FROM seller_windows
)
SELECT
    seller_group,
    band_2017,
    band_2018,
    COUNT(*) AS sellers,
    SUM(sales_2017) AS item_sales_2017,
    SUM(sales_2018) AS item_sales_2018
FROM banded
GROUP BY seller_group, band_2017, band_2018
ORDER BY seller_group, band_2017, band_2018;
