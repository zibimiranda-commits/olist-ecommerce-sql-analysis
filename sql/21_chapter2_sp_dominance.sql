-- Episode 15 | "Why Do Buyers Outside Sao Paulo Buy from SP Sellers?"
-- Windows: January-August (purchase timestamps). National origin split: 2017 and 2018.
-- Category analyses: 2018 only.
-- Item sales = SUM(order_items.price), freight excluded. One row of order_items = one item sold.
-- Origin of a sale = seller_state compared with the buyer's customer_state (registered states).
-- Category names: the English translation is matched with LIKE 'name%' because an exact
-- match returned 0 rows while LIKE worked; the cause has not been confirmed.
-- Category queries use DECLARE @cat: run each batch (up to GO) as a whole, changing @cat.
-- Results below were checked in SSMS on 27-28 Oct 2026.
USE olist;
GO

-- QUERY 1. Origin of the purchases of buyers outside SP (national, both years).
-- Reference: buyers outside SP = item sales 1,987,787.18 (2017) | 4,410,293.57 (2018).
-- Result: 2017 SP 1,235,194.05 (62.1%) | own state 121,980.56 (6.1%) | other states 630,612.57 (31.7%)
--         2018 SP 2,705,031.81 (61.3%) | own state 352,402.83 (8.0%) | other states 1,352,858.93 (30.7%)
SELECT YEAR(O.order_purchase_timestamp) AS yr,
       CASE WHEN S.seller_state = C.customer_state THEN 'Own state'
            WHEN S.seller_state = 'SP'             THEN 'SP'
            ELSE 'Other states' END      AS seller_origin,
       SUM(OI.price)                      AS item_sales
FROM orders AS O
INNER JOIN customers   AS C  ON C.customer_id = O.customer_id
INNER JOIN order_items AS OI ON OI.order_id   = O.order_id
INNER JOIN sellers     AS S  ON S.seller_id   = OI.seller_id
WHERE YEAR(O.order_purchase_timestamp) IN (2017, 2018)
  AND MONTH(O.order_purchase_timestamp) BETWEEN 1 AND 8
  AND C.customer_state <> 'SP'
GROUP BY YEAR(O.order_purchase_timestamp),
         CASE WHEN S.seller_state = C.customer_state THEN 'Own state'
              WHEN S.seller_state = 'SP'             THEN 'SP'
              ELSE 'Other states' END
ORDER BY yr, seller_origin;
GO

-- QUERY 2A. Origin of the sales by category, buyers outside SP, 2018.
-- Check: the 73 rows add up to 4,410,293.57 (Query 2B). Top rows: health_beauty 468,152.25,
-- watches_gifts 454,615.00, sports_leisure 316,946.57, computers_accessories 293,468.18, bed_bath_table 267,279.41.
SELECT COALESCE(RTRIM(T.product_category_name_english),
                P.product_category_name, 'no category') AS category,
       SUM(OI.price) AS total_sales,
       ROUND(100.0 * SUM(CASE WHEN S.seller_state = 'SP'
                              THEN OI.price ELSE 0 END) / SUM(OI.price), 1) AS pct_sp,
       ROUND(100.0 * SUM(CASE WHEN S.seller_state = C.customer_state
                              THEN OI.price ELSE 0 END) / SUM(OI.price), 1) AS pct_own_state,
       ROUND(100.0 * SUM(CASE WHEN S.seller_state <> 'SP'
                               AND S.seller_state <> C.customer_state
                              THEN OI.price ELSE 0 END) / SUM(OI.price), 1) AS pct_other_states
FROM orders AS O
INNER JOIN customers   AS C  ON C.customer_id = O.customer_id
INNER JOIN order_items AS OI ON OI.order_id   = O.order_id
INNER JOIN sellers     AS S  ON S.seller_id   = OI.seller_id
INNER JOIN products    AS P  ON P.product_id  = OI.product_id
LEFT JOIN product_category_name_translation AS T
       ON P.product_category_name = T.product_category_name
WHERE YEAR(O.order_purchase_timestamp) = 2018
  AND MONTH(O.order_purchase_timestamp) BETWEEN 1 AND 8
  AND C.customer_state <> 'SP'
GROUP BY COALESCE(RTRIM(T.product_category_name_english),
                  P.product_category_name, 'no category')
ORDER BY total_sales DESC;
GO

-- QUERY 2B. Control total for Query 2A. Expected: 4,410,293.57 (result: 4410293.57).
SELECT SUM(OI.price) AS total_sales
FROM orders AS O
INNER JOIN customers   AS C  ON C.customer_id = O.customer_id
INNER JOIN order_items AS OI ON OI.order_id   = O.order_id
INNER JOIN sellers     AS S  ON S.seller_id   = OI.seller_id
INNER JOIN products    AS P  ON P.product_id  = OI.product_id
WHERE YEAR(O.order_purchase_timestamp) = 2018
  AND MONTH(O.order_purchase_timestamp) BETWEEN 1 AND 8
  AND C.customer_state <> 'SP';
GO

-- QUERY 3. Selection rule for the four categories:
-- more than R$ 50,000 of sales outside SP AND at least 75% from SP sellers, all categories.
-- Expected from the Query 2A output: 4 rows -- watches_gifts (454,615.00 | 76.9%),
-- bed_bath_table (267,279.41 | 85.1%), baby (154,173.91 | 78.5%), office_furniture (81,914.28 | 87.2%).
;WITH c AS (
    SELECT COALESCE(RTRIM(T.product_category_name_english),
                    P.product_category_name, 'no category') AS category,
           SUM(OI.price) AS sales,
           SUM(CASE WHEN S.seller_state = 'SP' THEN OI.price ELSE 0 END) AS sp_sales
    FROM orders AS O
    INNER JOIN customers   AS C  ON C.customer_id = O.customer_id
    INNER JOIN order_items AS OI ON OI.order_id   = O.order_id
    INNER JOIN sellers     AS S  ON S.seller_id   = OI.seller_id
    INNER JOIN products    AS P  ON P.product_id  = OI.product_id
    LEFT JOIN product_category_name_translation AS T
           ON P.product_category_name = T.product_category_name
    WHERE YEAR(O.order_purchase_timestamp) = 2018
      AND MONTH(O.order_purchase_timestamp) BETWEEN 1 AND 8
      AND C.customer_state <> 'SP'
    GROUP BY COALESCE(RTRIM(T.product_category_name_english),
                      P.product_category_name, 'no category')
)
SELECT category, ROUND(sales, 2) AS sales,
       ROUND(100.0 * sp_sales / sales, 1) AS pct_sp
FROM c
WHERE sales > 50000
  AND ROUND(100.0 * sp_sales / sales, 1) >= 75
ORDER BY sales DESC;
GO

-- QUERY 4. bed_bath_table: products sold by SP sellers to buyers outside SP (top 15), 2018.
-- Result: 1,005 products, R$ 227,569.03 (85.1% of 267,279.41). Top product 2.3% (5,281.68); top 15 = 17.5%.
;WITH sp_sales AS (
    SELECT OI.product_id,
           COUNT(*)                     AS items_sold,
           COUNT(DISTINCT O.order_id)   AS orders,
           COUNT(DISTINCT OI.seller_id) AS sp_sellers,
           SUM(OI.price)                AS sp_sales
    FROM orders AS O
    INNER JOIN customers   AS C  ON C.customer_id = O.customer_id
    INNER JOIN order_items AS OI ON OI.order_id   = O.order_id
    INNER JOIN sellers     AS S  ON S.seller_id   = OI.seller_id
    INNER JOIN products    AS P  ON P.product_id  = OI.product_id
    LEFT JOIN product_category_name_translation AS T
           ON P.product_category_name = T.product_category_name
    WHERE YEAR(O.order_purchase_timestamp) = 2018
      AND MONTH(O.order_purchase_timestamp) BETWEEN 1 AND 8
      AND C.customer_state <> 'SP'
      AND S.seller_state = 'SP'
      AND T.product_category_name_english LIKE 'bed_bath_table%'
    GROUP BY OI.product_id
)
SELECT TOP 15
       product_id, items_sold, orders, sp_sellers, sp_sales,
       ROUND(100.0 * sp_sales / SUM(sp_sales) OVER (), 1) AS pct_of_category_sp_sales,
       ROUND(100.0 * SUM(sp_sales) OVER (ORDER BY sp_sales DESC, product_id
                                         ROWS UNBOUNDED PRECEDING)
             / SUM(sp_sales) OVER (), 1)                  AS cumulative_pct,
       COUNT(*) OVER ()                                   AS products_total,
       SUM(sp_sales) OVER ()                              AS category_sp_sales
FROM sp_sales
ORDER BY sp_sales DESC, product_id;
GO

-- QUERY 5. bed_bath_table: how many of the SP product IDs are also sold by a non-SP seller
-- (to buyers outside SP, same window)?
-- Result: 1,005 SP products | 1 also sold by a non-SP seller (0.1%) | SP sales 227,569.03 | 89.00 (0.0%).
;WITH base AS (
    SELECT OI.product_id,
           CASE WHEN S.seller_state = 'SP' THEN 'SP' ELSE 'Non-SP' END AS origin,
           SUM(OI.price) AS sales
    FROM orders AS O
    INNER JOIN customers   AS C  ON C.customer_id = O.customer_id
    INNER JOIN order_items AS OI ON OI.order_id   = O.order_id
    INNER JOIN sellers     AS S  ON S.seller_id   = OI.seller_id
    INNER JOIN products    AS P  ON P.product_id  = OI.product_id
    LEFT JOIN product_category_name_translation AS T
           ON P.product_category_name = T.product_category_name
    WHERE YEAR(O.order_purchase_timestamp) = 2018
      AND MONTH(O.order_purchase_timestamp) BETWEEN 1 AND 8
      AND C.customer_state <> 'SP'
      AND T.product_category_name_english LIKE 'bed_bath_table%'
    GROUP BY OI.product_id,
             CASE WHEN S.seller_state = 'SP' THEN 'SP' ELSE 'Non-SP' END
),
sp     AS (SELECT product_id, sales FROM base WHERE origin = 'SP'),
non_sp AS (SELECT product_id        FROM base WHERE origin = 'Non-SP')
SELECT COUNT(*)                                                         AS sp_products,
       SUM(CASE WHEN N.product_id IS NOT NULL THEN 1 ELSE 0 END)        AS also_sold_by_non_sp,
       ROUND(100.0 * SUM(CASE WHEN N.product_id IS NOT NULL THEN 1 ELSE 0 END)
             / COUNT(*), 1)                                             AS pct_of_products,
       SUM(sp.sales)                                                    AS sp_sales,
       SUM(CASE WHEN N.product_id IS NOT NULL THEN sp.sales ELSE 0 END) AS sp_sales_shared_products,
       ROUND(100.0 * SUM(CASE WHEN N.product_id IS NOT NULL THEN sp.sales ELSE 0 END)
             / SUM(sp.sales), 1)                                        AS pct_of_sp_value
FROM sp
LEFT JOIN non_sp AS N ON N.product_id = sp.product_id;
GO

-- QUERY 6. Sellers per product ID, whole dataset (all dates, all buyers).
-- Result: 32,951 products | 1,225 with 2+ sellers (3.7%; the other 96.3% have one) | 482 sold by SP and non-SP sellers.
SELECT COUNT(*)                                                    AS products,
       SUM(CASE WHEN sellers >= 2 THEN 1 ELSE 0 END)               AS products_with_2plus_sellers,
       SUM(CASE WHEN sp_sellers >= 1 AND non_sp_sellers >= 1
                THEN 1 ELSE 0 END)                                 AS products_sold_by_sp_and_non_sp
FROM (
    SELECT OI.product_id,
           COUNT(DISTINCT OI.seller_id) AS sellers,
           COUNT(DISTINCT CASE WHEN S.seller_state = 'SP'  THEN OI.seller_id END) AS sp_sellers,
           COUNT(DISTINCT CASE WHEN S.seller_state <> 'SP' THEN OI.seller_id END) AS non_sp_sellers
    FROM order_items AS OI
    INNER JOIN sellers AS S ON S.seller_id = OI.seller_id
    GROUP BY OI.product_id
) AS x;
GO

-- QUERY 7. Sellers by seller state for one category (buyers outside SP, 2018). Change @cat.
-- Medians are read only for seller states with at least 30 items.
-- bed_bath_table: SP 95 sellers | 2,483 items | 1,005 products | 227,569.03 | 85.1% | median price 74.90 | median weight 1,133 g
--                 SC 9 | 219 | 95 | 21,289.73 | 8.0%; the 10 seller states add up to 267,279.41 and 2,880 items.
-- baby:           SP 99 | 734 | 317 | 121,062.03 | 78.5%   (PR 14 sellers | 83 items | 38 products | 12,141.61 | 7.9%)
-- watches_gifts:  SP 43 | 1,801 | 481 | 349,587.01 | 76.9% (RJ 10 | 307 | 51 | 58,213.84 | 12.8%); total 454,615.00
-- office_furniture: SP 11 | 481 | 132 | 71,452.29 | 87.2% (RJ 1 | 13 | 4 | 5,387.00); total 81,914.28; only SP has 30+ items.
DECLARE @cat VARCHAR(60) = 'bed_bath_table';   -- 'baby', 'watches_gifts', 'office_furniture'

;WITH rows_ AS (
    SELECT S.seller_state, OI.seller_id, OI.product_id, OI.price, P.product_weight_g
    FROM orders AS O
    INNER JOIN customers   AS C  ON C.customer_id = O.customer_id
    INNER JOIN order_items AS OI ON OI.order_id   = O.order_id
    INNER JOIN sellers     AS S  ON S.seller_id   = OI.seller_id
    INNER JOIN products    AS P  ON P.product_id  = OI.product_id
    LEFT JOIN product_category_name_translation AS T
           ON P.product_category_name = T.product_category_name
    WHERE YEAR(O.order_purchase_timestamp) = 2018
      AND MONTH(O.order_purchase_timestamp) BETWEEN 1 AND 8
      AND C.customer_state <> 'SP'
      AND T.product_category_name_english LIKE @cat + '%'
),
agg AS (
    SELECT seller_state,
           COUNT(DISTINCT seller_id)  AS sellers,
           COUNT(*)                   AS items,
           COUNT(DISTINCT product_id) AS products_sold,
           SUM(price)                 AS sales,
           ROUND(100.0 * SUM(price) / SUM(SUM(price)) OVER (), 1) AS pct_of_category
    FROM rows_
    GROUP BY seller_state
),
med AS (
    SELECT DISTINCT seller_state,
           PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY price)
               OVER (PARTITION BY seller_state)            AS median_price,
           PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY product_weight_g)
               OVER (PARTITION BY seller_state)            AS median_weight_g
    FROM rows_
)
SELECT TOP 10 A.seller_state, A.sellers, A.items, A.products_sold, A.sales,
       A.pct_of_category,
       ROUND(M.median_price, 2)    AS median_price,
       ROUND(M.median_weight_g, 0) AS median_weight_g
FROM agg AS A
INNER JOIN med AS M ON M.seller_state = A.seller_state
ORDER BY A.sales DESC;
GO

-- QUERY 8. Buyer states for one category, SP buyers included (2018). Change @cat.
-- For SP buyers, "own state" = SP. ALL STATES minus the SP row = buyers outside SP.
-- bed_bath_table: SP 3,004 items | 270,789.85 | 87.6% SP sellers (103 sellers); ALL 5,884 | 538,069.26 | 86.4% (114 SP sellers)
--                 ALL minus SP = 2,880 items | 267,279.41 -> SP sellers 85.1% outside SP. Best local share: SC 15.4% (5 local sellers).
-- baby:           SP buyers 764 | 102,626.79 | 82.7% (102 sellers); ALL 1,776 | 256,800.70 | 80.2%; outside SP 78.5%. Best local: MG 13.8% (10).
-- watches_gifts:  SP buyers 1,383 | 254,235.94 | 82.0% (38); ALL 3,703 | 708,850.94 | 78.7%; outside SP 76.9%. Best local: RJ 16.2% (7).
-- office_furniture: SP buyers 366 | 61,735.83 | 93.1% (12); ALL 883 | 143,650.11 | 89.7%; outside SP 87.2%. Best local: PR 20.2% (2).
-- BA (Bahia) shows no local sale in any of the four categories (53 to 141 items each).
DECLARE @cat VARCHAR(60) = 'bed_bath_table';   -- 'baby', 'watches_gifts', 'office_furniture'

;WITH r AS (
    SELECT C.customer_state AS buyer_state, S.seller_state,
           OI.seller_id, OI.product_id, OI.price
    FROM orders AS O
    INNER JOIN customers   AS C  ON C.customer_id = O.customer_id
    INNER JOIN order_items AS OI ON OI.order_id   = O.order_id
    INNER JOIN sellers     AS S  ON S.seller_id   = OI.seller_id
    INNER JOIN products    AS P  ON P.product_id  = OI.product_id
    LEFT JOIN product_category_name_translation AS T
           ON P.product_category_name = T.product_category_name
    WHERE YEAR(O.order_purchase_timestamp) = 2018
      AND MONTH(O.order_purchase_timestamp) BETWEEN 1 AND 8
      AND T.product_category_name_english LIKE @cat + '%'
)
SELECT COALESCE(buyer_state, 'ALL STATES') AS buyer_state,
       COUNT(*)   AS items,
       SUM(price) AS sales,
       ROUND(100.0 * SUM(CASE WHEN seller_state = 'SP' THEN price ELSE 0 END)
             / SUM(price), 1) AS pct_sp_sellers,
       CASE WHEN GROUPING(buyer_state) = 1 THEN NULL
            ELSE ROUND(100.0 * SUM(CASE WHEN seller_state = buyer_state THEN price ELSE 0 END)
                       / SUM(price), 1) END AS pct_own_state_sellers,
       COUNT(DISTINCT CASE WHEN seller_state = 'SP' THEN seller_id END) AS sp_sellers,
       CASE WHEN GROUPING(buyer_state) = 1 THEN NULL
            ELSE COUNT(DISTINCT CASE WHEN seller_state = buyer_state THEN seller_id END)
            END AS own_state_sellers
FROM r
GROUP BY ROLLUP (buyer_state)
ORDER BY GROUPING(buyer_state), sales DESC;
GO

-- APPENDIX (context, not used in the post). Basket of SP buyers vs buyers in other states, 2017-2018.
-- Item sales tie to 3,113,000.32 | 7,385,905.80. Orders without items are absent (INNER JOIN):
-- 22,693 | 53,774 orders vs 22,968 | 53,991 in Episode 14.
-- Median order value 2018: SP 79.90 | other states 94.90; freight 14.0% vs 19.1% of item sales.
IF OBJECT_ID('tempdb..#order_level') IS NOT NULL DROP TABLE #order_level;

SELECT O.order_id,
       YEAR(O.order_purchase_timestamp) AS yr,
       CASE WHEN C.customer_state = 'SP' THEN 'SP' ELSE 'Other states' END AS buyer_group,
       COUNT(OI.order_item_id) AS items,
       SUM(OI.price)           AS item_sales,
       SUM(OI.freight_value)   AS freight
INTO #order_level
FROM orders AS O
INNER JOIN customers   AS C  ON C.customer_id = O.customer_id
INNER JOIN order_items AS OI ON OI.order_id   = O.order_id
WHERE YEAR(O.order_purchase_timestamp) IN (2017, 2018)
  AND MONTH(O.order_purchase_timestamp) BETWEEN 1 AND 8
GROUP BY O.order_id, YEAR(O.order_purchase_timestamp),
         CASE WHEN C.customer_state = 'SP' THEN 'SP' ELSE 'Other states' END;
GO

WITH medians AS (
    SELECT DISTINCT yr, buyer_group,
           PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY item_sales)
               OVER (PARTITION BY yr, buyer_group) AS median_order_value,
           PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY freight)
               OVER (PARTITION BY yr, buyer_group) AS median_freight
    FROM #order_level
)
SELECT L.yr, L.buyer_group,
       COUNT(*)                                          AS orders,
       ROUND(1.0 * SUM(L.items) / COUNT(*), 2)           AS avg_items_per_order,
       ROUND(SUM(L.item_sales) / COUNT(*), 2)            AS avg_order_value,
       ROUND(M.median_order_value, 2)                    AS median_order_value,
       ROUND(SUM(L.freight) / COUNT(*), 2)               AS avg_freight_per_order,
       ROUND(M.median_freight, 2)                        AS median_freight,
       ROUND(100.0 * SUM(L.freight) / SUM(L.item_sales), 1) AS freight_pct_of_item_sales
FROM #order_level AS L
INNER JOIN medians AS M ON M.yr = L.yr AND M.buyer_group = L.buyer_group
GROUP BY L.yr, L.buyer_group, M.median_order_value, M.median_freight
ORDER BY L.yr, L.buyer_group;
GO
