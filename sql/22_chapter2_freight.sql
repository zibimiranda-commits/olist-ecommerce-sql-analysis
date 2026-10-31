-- Episode 16 | "What Does It Cost to Buy from Sao Paulo?" -- freight by seller origin
-- Buyers outside SP only. Windows: January-August 2017 and 2018 (purchase timestamps).
-- Item sales = SUM(order_items.price), freight excluded. Freight = SUM(order_items.freight_value):
-- the amount charged to the buyer, not the carrier's cost. One row of order_items = one item sold.
-- Origin of a sale = seller_state compared with the buyer's customer_state (registered states):
--   'Own state' (same state), 'SP' (seller in SP, buyer elsewhere), 'Other states'.
-- Medians come from a second CTE (PERCENTILE_CONT) with DISTINCT.
-- Cells under 30 items are not read. Results below were checked in SSMS on 29-30 Oct 2026.
USE olist;
GO

-- QUERY 1. Freight by seller origin and year, buyers outside SP (national).
-- Checks: the three origins add up to item sales 1,987,787.18 (2017) and 4,410,293.57 (2018);
--         items_with_freight = items on every row (no missing freight).
-- Result (yr | origin | items | item_sales | avg | median | freight % of price):
--   2017 Other states 4,204 | 630,612.57  | 24.80 | 19.38 | 16.5
--   2017 Own state    1,018 | 121,980.56  | 14.39 | 12.48 | 12.0
--   2017 SP          10,456 | 1,235,194.05 | 21.69 | 17.16 | 18.4
--   2018 Other states 8,510 | 1,352,858.93 | 29.54 | 22.36 | 18.6
--   2018 Own state    2,546 | 352,402.83  | 15.86 | 13.69 | 11.5
--   2018 SP          23,081 | 2,705,031.81 | 23.83 | 18.76 | 20.3
-- Reading: % = total freight / total item sales (not an average of item percentages).
;WITH rows_ AS (
    SELECT YEAR(O.order_purchase_timestamp) AS yr,
           CASE WHEN S.seller_state = C.customer_state THEN 'Own state'
                WHEN S.seller_state = 'SP'             THEN 'SP'
                ELSE 'Other states' END                AS seller_origin,
           OI.price,
           OI.freight_value
    FROM orders AS O
    INNER JOIN customers   AS C  ON C.customer_id = O.customer_id
    INNER JOIN order_items AS OI ON OI.order_id   = O.order_id
    INNER JOIN sellers     AS S  ON S.seller_id   = OI.seller_id
    WHERE YEAR(O.order_purchase_timestamp) IN (2017, 2018)
      AND MONTH(O.order_purchase_timestamp) BETWEEN 1 AND 8
      AND C.customer_state <> 'SP'
), agg AS (
    SELECT yr, seller_origin,
           COUNT(*)             AS items,
           COUNT(freight_value) AS items_with_freight,
           SUM(price)           AS item_sales,
           SUM(freight_value)   AS freight,
           AVG(freight_value)   AS avg_freight
    FROM rows_
    GROUP BY yr, seller_origin
), med AS (
    SELECT DISTINCT yr, seller_origin,
           PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY freight_value)
               OVER (PARTITION BY yr, seller_origin) AS median_freight
    FROM rows_
)
SELECT A.yr, A.seller_origin, A.items, A.items_with_freight,
       A.item_sales, A.freight,
       ROUND(A.avg_freight, 2)                    AS avg_freight,
       ROUND(M.median_freight, 2)                 AS median_freight,
       ROUND(100.0 * A.freight / A.item_sales, 1) AS freight_pct_of_price
FROM agg AS A
INNER JOIN med AS M ON M.yr = A.yr AND M.seller_origin = A.seller_origin
ORDER BY A.yr, A.seller_origin;
GO

-- QUERY 2. Same buyer state: the 8 largest buyer states outside SP (by 2018 items), both years.
-- Control (second SELECT below): the 8 states together = 12,478 items | 1,519,316.52 (2017)
--                                and 27,577 items | 3,415,955.90 (2018); the origins of query 2 must add up to it.
-- The 8 states: BA, DF, GO, MG, PR, RJ, RS, SC.
-- Cells under 30 items are not read: BA (15 and 29 own-state items), DF 2017 (6), GO 2017 (4).
-- Reading (average freight, SP vs own state, cells of 30+ items): MG 19.04 vs 14.97 (2017), 21.35 vs 18.13 (2018);
--   PR 20.60 vs 15.05, 21.26 vs 16.60; RJ 19.27 vs 12.74, 21.37 vs 12.02; RS 19.98 vs 12.69, 21.70 vs 17.17;
--   SC 19.01 vs 15.87, 22.51 vs 17.33; DF 2018 20.59 vs 8.86; GO 2018 21.14 vs 11.99 (SP higher in every readable cell,
--   by 3.14 to 11.73). Own-state sellers made only 1.5% (BA), 2.9% (DF) and 2.6% (GO) of 2018 items.
-- SP vs Other states: SP average freight lower in 15 of 16 state-years (exception: PR 2017, 20.60 vs 20.29).
;WITH rows_ AS (
    SELECT YEAR(O.order_purchase_timestamp) AS yr,
           C.customer_state                 AS buyer_state,
           CASE WHEN S.seller_state = C.customer_state THEN 'Own state'
                WHEN S.seller_state = 'SP'             THEN 'SP'
                ELSE 'Other states' END     AS seller_origin,
           OI.price,
           OI.freight_value
    FROM orders AS O
    INNER JOIN customers   AS C  ON C.customer_id = O.customer_id
    INNER JOIN order_items AS OI ON OI.order_id   = O.order_id
    INNER JOIN sellers     AS S  ON S.seller_id   = OI.seller_id
    WHERE YEAR(O.order_purchase_timestamp) IN (2017, 2018)
      AND MONTH(O.order_purchase_timestamp) BETWEEN 1 AND 8
      AND C.customer_state <> 'SP'
), top_states AS (
    SELECT TOP 8 buyer_state
    FROM rows_
    WHERE yr = 2018
    GROUP BY buyer_state
    ORDER BY COUNT(*) DESC
), agg AS (
    SELECT yr, buyer_state, seller_origin,
           COUNT(*)           AS items,
           SUM(price)         AS item_sales,
           SUM(freight_value) AS freight,
           AVG(freight_value) AS avg_freight
    FROM rows_
    WHERE buyer_state IN (SELECT buyer_state FROM top_states)
    GROUP BY yr, buyer_state, seller_origin
), med AS (
    SELECT DISTINCT yr, buyer_state, seller_origin,
           PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY freight_value)
               OVER (PARTITION BY yr, buyer_state, seller_origin) AS median_freight
    FROM rows_
    WHERE buyer_state IN (SELECT buyer_state FROM top_states)
)
SELECT A.buyer_state, A.yr, A.seller_origin, A.items, A.item_sales,
       ROUND(A.avg_freight, 2)                    AS avg_freight,
       ROUND(M.median_freight, 2)                 AS median_freight,
       ROUND(100.0 * A.freight / A.item_sales, 1) AS freight_pct_of_price
FROM agg AS A
INNER JOIN med AS M
        ON M.yr = A.yr AND M.buyer_state = A.buyer_state
       AND M.seller_origin = A.seller_origin
ORDER BY A.buyer_state, A.yr, A.seller_origin;
GO

-- Control for query 2: same 8 states, plain count without the origin column.
-- Result: 2017 = 12,478 items | 1,519,316.52 ; 2018 = 27,577 items | 3,415,955.90.
SELECT YEAR(O.order_purchase_timestamp) AS yr,
       COUNT(*) AS items, SUM(OI.price) AS item_sales
FROM orders AS O
INNER JOIN customers   AS C  ON C.customer_id = O.customer_id
INNER JOIN order_items AS OI ON OI.order_id   = O.order_id
WHERE YEAR(O.order_purchase_timestamp) IN (2017, 2018)
  AND MONTH(O.order_purchase_timestamp) BETWEEN 1 AND 8
  AND C.customer_state IN (
        SELECT TOP 8 C2.customer_state
        FROM orders AS O2
        INNER JOIN customers   AS C2  ON C2.customer_id = O2.customer_id
        INNER JOIN order_items AS OI2 ON OI2.order_id   = O2.order_id
        WHERE YEAR(O2.order_purchase_timestamp) = 2018
          AND MONTH(O2.order_purchase_timestamp) BETWEEN 1 AND 8
          AND C2.customer_state <> 'SP'
        GROUP BY C2.customer_state
        ORDER BY COUNT(*) DESC)
GROUP BY YEAR(O.order_purchase_timestamp)
ORDER BY yr;
GO

-- QUERY 3. Same category: the four categories of episode 15, buyers outside SP, 2018 only.
-- Category names matched with LIKE 'name%' (see script 21). Median weight = product_weight_g.
-- Checks: sales of the three origins add up to 454,615.00 (watches_gifts), 267,279.41 (bed_bath_table),
--         154,173.91 (baby), 81,914.28 (office_furniture); items_with_freight = items.
-- Not read: office_furniture, Own state (9 items) and Other states (27 items) are under 30.
-- Result (category | origin | items | avg | median | freight % | median weight g):
--   baby             Other 207 | 30.93 | 20.15 | 24.8 |  650    Own  71 | 14.96 | 13.69 | 14.6 |  450    SP   734 | 29.96 | 20.19 | 18.2 |  950
--   bed_bath_table   Other 319 | 29.80 | 23.92 | 30.2 | 1,600   Own  78 | 15.97 | 14.32 | 15.2 | 1,250   SP 2,483 | 22.54 | 19.46 | 24.6 | 1,133
--   watches_gifts    Other 408 | 24.54 | 20.14 | 12.2 |  500    Own 111 | 11.69 |  9.77 |  5.6 |  501    SP 1,801 | 19.54 | 18.82 | 10.1 |  335
--   office_furniture SP 481 | 53.18 | 45.25 | 35.8 | 11,875 (the other two origins are under 30 items)
-- Reading (median freight): SP minus own state = +6.50 (baby), +5.14 (bed_bath_table), +9.05 (watches_gifts);
--   SP minus other states = +0.04, -4.46, -1.32 (nationally: -3.60). The gap varies by category.
;WITH base AS (
    SELECT CASE WHEN T.product_category_name_english LIKE 'watches_gifts%'    THEN 'watches_gifts'
                WHEN T.product_category_name_english LIKE 'bed_bath_table%'   THEN 'bed_bath_table'
                WHEN T.product_category_name_english LIKE 'baby%'             THEN 'baby'
                WHEN T.product_category_name_english LIKE 'office_furniture%' THEN 'office_furniture'
           END AS category,
           CASE WHEN S.seller_state = C.customer_state THEN 'Own state'
                WHEN S.seller_state = 'SP'             THEN 'SP'
                ELSE 'Other states' END AS seller_origin,
           OI.price,
           OI.freight_value,
           P.product_weight_g
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
), rows_ AS (
    SELECT * FROM base WHERE category IS NOT NULL
), agg AS (
    SELECT category, seller_origin,
           COUNT(*)             AS items,
           COUNT(freight_value) AS items_with_freight,
           SUM(price)           AS item_sales,
           SUM(freight_value)   AS freight,
           AVG(freight_value)   AS avg_freight
    FROM rows_
    GROUP BY category, seller_origin
), med AS (
    SELECT DISTINCT category, seller_origin,
           PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY freight_value)
               OVER (PARTITION BY category, seller_origin) AS median_freight,
           PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY product_weight_g)
               OVER (PARTITION BY category, seller_origin) AS median_weight_g
    FROM rows_
)
SELECT A.category, A.seller_origin, A.items, A.items_with_freight, A.item_sales,
       ROUND(A.avg_freight, 2)                    AS avg_freight,
       ROUND(M.median_freight, 2)                 AS median_freight,
       ROUND(100.0 * A.freight / A.item_sales, 1) AS freight_pct_of_price,
       ROUND(M.median_weight_g, 0)                AS median_weight_g
FROM agg AS A
INNER JOIN med AS M
        ON M.category = A.category AND M.seller_origin = A.seller_origin
ORDER BY A.category, A.seller_origin;
GO
