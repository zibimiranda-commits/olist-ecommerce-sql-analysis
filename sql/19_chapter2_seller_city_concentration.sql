-- Episode 13 | "Wide or Deep? How Sao Paulo Gets Its Weight" -- seller side (script 19)
-- Windows: January-August 2017 vs January-August 2018 (purchase timestamps).
-- Item sales = SUM(order_items.price), freight excluded, no order-status filter (Chapter 1 definition).
-- City = city + state pair (the state is always part of the grouping). City comes from dbo.seller_city_map
-- (run 17_seller_city_map.sql first); sellers with an unresolved city stay in the state totals but are not counted as cities.
-- Reference totals to tie to: item sales 3,113,000.32 | 7,385,905.80; active sellers 1,227 | 2,383.
USE olist;
GO

-- Results checked in SSMS on 24 Oct 2026: query 1 ALL STATES = 1,227 | 2,383 sellers, 335 | 490 cities, 3,113,000.32 | 7,385,905.80;
-- SP = 141 | 195 cities; query 2 SP 2018 = mean 24,468.83, median 2,826.27, top city 31.2% (sao paulo).

-- QUERY 1. Active sellers, active cities and item sales per seller state (both years side by side).
-- Checks: ALL STATES row = 1,227 | 2,383 sellers and 3,113,000.32 | 7,385,905.80 sales;
--         SP row = 723 | 1,417 sellers, 2,016,153.52 | 4,798,484.69 sales, 4 | 8 sellers without a usable city.
;WITH seller_sales AS (
    SELECT OI.seller_id,
           SUM(CASE WHEN YEAR(O.order_purchase_timestamp) = 2017 THEN OI.price ELSE 0 END) AS sales_2017,
           SUM(CASE WHEN YEAR(O.order_purchase_timestamp) = 2018 THEN OI.price ELSE 0 END) AS sales_2018
    FROM order_items AS OI
    INNER JOIN orders AS O ON O.order_id = OI.order_id
    WHERE YEAR(O.order_purchase_timestamp) IN (2017, 2018)
      AND MONTH(O.order_purchase_timestamp) BETWEEN 1 AND 8
    GROUP BY OI.seller_id
), seller_geo AS (
    SELECT S.seller_id, S.seller_state,
           CASE WHEN M.status = 'unresolved' THEN NULL
                ELSE LOWER(LTRIM(RTRIM(COALESCE(M.clean_city, S.seller_city)))) END AS city_clean
    FROM sellers AS S
    LEFT JOIN dbo.seller_city_map AS M
           ON M.raw_city = S.seller_city
          AND (M.raw_state IS NULL OR M.raw_state = S.seller_state)
)
SELECT COALESCE(G.seller_state, 'ALL STATES') AS seller_state,
       SUM(CASE WHEN SS.sales_2017 > 0 THEN 1 ELSE 0 END) AS sellers_2017,
       SUM(CASE WHEN SS.sales_2018 > 0 THEN 1 ELSE 0 END) AS sellers_2018,
       COUNT(DISTINCT CASE WHEN SS.sales_2017 > 0 AND G.city_clean IS NOT NULL
                           THEN G.seller_state + '|' + G.city_clean END) AS cities_2017,
       COUNT(DISTINCT CASE WHEN SS.sales_2018 > 0 AND G.city_clean IS NOT NULL
                           THEN G.seller_state + '|' + G.city_clean END) AS cities_2018,
       SUM(CASE WHEN SS.sales_2017 > 0 AND G.city_clean IS NULL THEN 1 ELSE 0 END) AS sellers_no_city_2017,
       SUM(CASE WHEN SS.sales_2018 > 0 AND G.city_clean IS NULL THEN 1 ELSE 0 END) AS sellers_no_city_2018,
       SUM(SS.sales_2017) AS sales_2017,
       SUM(SS.sales_2018) AS sales_2018
FROM seller_geo AS G
INNER JOIN seller_sales AS SS ON SS.seller_id = G.seller_id
GROUP BY ROLLUP (G.seller_state)
ORDER BY GROUPING(G.seller_state), sales_2018 DESC;
GO

-- QUERY 2. Intensity: item sales per active city, median per city and share of the largest city, per state and year.
-- Only sellers with a usable city are in this query (see query 3 for the rest).
-- Checks: for each state and year, 'cities' must equal cities_2017 / cities_2018 of query 1;
--         'sales_in_cities' = state sales (query 1) minus 'sales_without_city' of query 3.
-- Flag: fewer than 5 active cities = small base (a presentation warning, not a reliability test).
;WITH seller_year AS (
    SELECT OI.seller_id, YEAR(O.order_purchase_timestamp) AS yr, SUM(OI.price) AS sales
    FROM order_items AS OI
    INNER JOIN orders AS O ON O.order_id = OI.order_id
    WHERE YEAR(O.order_purchase_timestamp) IN (2017, 2018)
      AND MONTH(O.order_purchase_timestamp) BETWEEN 1 AND 8
    GROUP BY OI.seller_id, YEAR(O.order_purchase_timestamp)
), seller_geo AS (
    SELECT S.seller_id, S.seller_state,
           CASE WHEN M.status = 'unresolved' THEN NULL
                ELSE LOWER(LTRIM(RTRIM(COALESCE(M.clean_city, S.seller_city)))) END AS city_clean
    FROM sellers AS S
    LEFT JOIN dbo.seller_city_map AS M
           ON M.raw_city = S.seller_city
          AND (M.raw_state IS NULL OR M.raw_state = S.seller_state)
), city_year AS (
    SELECT G.seller_state, G.city_clean, SY.yr,
           COUNT(*) AS sellers, SUM(SY.sales) AS sales
    FROM seller_geo AS G
    INNER JOIN seller_year AS SY ON SY.seller_id = G.seller_id
    WHERE G.city_clean IS NOT NULL
    GROUP BY G.seller_state, G.city_clean, SY.yr
), ranked AS (
    SELECT seller_state, city_clean, yr, sellers, sales,
           ROW_NUMBER() OVER (PARTITION BY seller_state, yr ORDER BY sales DESC) AS rk,
           PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY sales) OVER (PARTITION BY seller_state, yr) AS median_sales,
           SUM(sales) OVER (PARTITION BY seller_state, yr) AS state_city_sales
    FROM city_year
)
SELECT seller_state, yr,
       COUNT(*) AS cities,
       SUM(sellers) AS sellers,
       MAX(state_city_sales) AS sales_in_cities,
       ROUND(MAX(state_city_sales) / COUNT(*), 2) AS mean_sales_per_city,
       ROUND(MAX(median_sales), 2) AS median_sales_per_city,
       ROUND(100.0 * MAX(CASE WHEN rk = 1 THEN sales END) / MAX(state_city_sales), 1) AS top_city_share_pct,
       MAX(CASE WHEN rk = 1 THEN city_clean END) AS top_city,
       CASE WHEN COUNT(*) < 5 THEN 'small base' ELSE '' END AS flag
FROM ranked
GROUP BY seller_state, yr
ORDER BY yr, sales_in_cities DESC;
GO

-- QUERY 3. Reconciliation: sales and sellers with and without a usable city, per state and year.
-- Checks: ALL STATES total_sales = 3,113,000.32 (2017) and 7,385,905.80 (2018); sellers = 1,227 and 2,383;
--         SP without a usable city = 4 sellers / 2,372.36 (2017) and 8 sellers / 27,063.56 (2018) (script 18, query 4).
;WITH seller_year AS (
    SELECT OI.seller_id, YEAR(O.order_purchase_timestamp) AS yr, SUM(OI.price) AS sales
    FROM order_items AS OI
    INNER JOIN orders AS O ON O.order_id = OI.order_id
    WHERE YEAR(O.order_purchase_timestamp) IN (2017, 2018)
      AND MONTH(O.order_purchase_timestamp) BETWEEN 1 AND 8
    GROUP BY OI.seller_id, YEAR(O.order_purchase_timestamp)
), seller_geo AS (
    SELECT S.seller_id, S.seller_state,
           CASE WHEN M.status = 'unresolved' THEN NULL
                ELSE LOWER(LTRIM(RTRIM(COALESCE(M.clean_city, S.seller_city)))) END AS city_clean
    FROM sellers AS S
    LEFT JOIN dbo.seller_city_map AS M
           ON M.raw_city = S.seller_city
          AND (M.raw_state IS NULL OR M.raw_state = S.seller_state)
)
SELECT SY.yr, COALESCE(G.seller_state, 'ALL STATES') AS seller_state,
       COUNT(*) AS sellers,
       SUM(CASE WHEN G.city_clean IS NULL THEN 1 ELSE 0 END) AS sellers_without_city,
       SUM(SY.sales) AS total_sales,
       SUM(CASE WHEN G.city_clean IS NOT NULL THEN SY.sales ELSE 0 END) AS sales_with_city,
       SUM(CASE WHEN G.city_clean IS NULL THEN SY.sales ELSE 0 END) AS sales_without_city
FROM seller_geo AS G
INNER JOIN seller_year AS SY ON SY.seller_id = G.seller_id
GROUP BY SY.yr, ROLLUP (G.seller_state)
ORDER BY SY.yr, GROUPING(G.seller_state), total_sales DESC;
GO

-- QUERY 4 (query 3 of the LinkedIn post). Concentration inside Sao Paulo state, 2018: how many cities carry 50% and 80% of city-attributed item sales?
-- Cumulative share over cities ranked by sales (ties broken by city name). Only sellers with a usable city.
-- Result (verified in SSMS, 24 Oct 2026): 195 cities | 6 cities pass 50% | 25 cities reach 80% | top city 31.2%.
-- Ties: 195 = cities_2018 of query 1 (SP); 31.2 = top_city_share_pct of query 2 (SP, 2018).
;WITH seller_year AS (
    SELECT OI.seller_id, SUM(OI.price) AS sales
    FROM order_items AS OI
    INNER JOIN orders AS O ON O.order_id = OI.order_id
    WHERE YEAR(O.order_purchase_timestamp) = 2018
      AND MONTH(O.order_purchase_timestamp) BETWEEN 1 AND 8
    GROUP BY OI.seller_id
), seller_geo AS (
    SELECT S.seller_id, S.seller_state,
           CASE WHEN M.status = 'unresolved' THEN NULL
                ELSE LOWER(LTRIM(RTRIM(COALESCE(M.clean_city, S.seller_city)))) END AS city_clean
    FROM sellers AS S
    LEFT JOIN dbo.seller_city_map AS M
           ON M.raw_city = S.seller_city
          AND (M.raw_state IS NULL OR M.raw_state = S.seller_state)
), city_sales AS (
    SELECT G.city_clean, SUM(SY.sales) AS sales
    FROM seller_geo AS G
    INNER JOIN seller_year AS SY ON SY.seller_id = G.seller_id
    WHERE G.seller_state = 'SP' AND G.city_clean IS NOT NULL
    GROUP BY G.city_clean
), ranked AS (
    SELECT city_clean, sales,
           ROW_NUMBER() OVER (ORDER BY sales DESC, city_clean) AS rk,
           SUM(sales) OVER (ORDER BY sales DESC, city_clean ROWS UNBOUNDED PRECEDING) AS cum_sales,
           SUM(sales) OVER () AS total_sales
    FROM city_sales
)
SELECT COUNT(*) AS cities,
       MIN(CASE WHEN cum_sales > 0.5 * total_sales  THEN rk END) AS cities_for_over_50pct,
       MIN(CASE WHEN cum_sales >= 0.8 * total_sales THEN rk END) AS cities_for_80pct,
       ROUND(100.0 * MAX(CASE WHEN rk = 1 THEN sales END) / MAX(total_sales), 1) AS top_city_share_pct
FROM ranked;
GO
