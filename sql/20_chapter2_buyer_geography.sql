-- Episode 14 | "Where Are the Buyers? Supply vs. Demand" -- buyer side
-- Windows: January-August 2017 vs January-August 2018 (purchase timestamps).
-- Item sales = SUM(order_items.price), freight excluded. Buyer = customer_unique_id.
-- customers has one row per customer_id (one per order); state and city are the registered ones.
-- Reference totals to tie to: orders 22,968 | 53,991; buyers 22,320 | 52,743;
--                             item sales 3,113,000.32 | 7,385,905.80.
-- Results below were checked in SSMS on 25-26 Oct 2026.
USE olist;
GO

-- QUERY 1. Can a buyer appear in more than one state?
-- Result: 2017 = 22,320 buyers, 4 in several states | 2018 = 52,743 buyers, 9 in several states.
-- Rule: a buyer is counted once per state where he or she ordered (sum over states = total + 4 | + 9).
;WITH buyer_state AS (
    SELECT YEAR(O.order_purchase_timestamp) AS yr,
           C.customer_unique_id,
           COUNT(DISTINCT C.customer_state) AS nb_states
    FROM orders AS O
    INNER JOIN customers AS C ON C.customer_id = O.customer_id
    WHERE YEAR(O.order_purchase_timestamp) IN (2017, 2018)
      AND MONTH(O.order_purchase_timestamp) BETWEEN 1 AND 8
    GROUP BY YEAR(O.order_purchase_timestamp), C.customer_unique_id
)
SELECT yr,
       COUNT(*) AS buyers,
       SUM(CASE WHEN nb_states > 1 THEN 1 ELSE 0 END) AS buyers_in_several_states
FROM buyer_state
GROUP BY yr
ORDER BY yr;
GO

-- QUERY 2. Orders, distinct buyers and item sales per buyer state (both years side by side).
-- Checks: ALL STATES = 22,968 | 53,991 orders, 22,320 | 52,743 buyers, 3,113,000.32 | 7,385,905.80 sales.
-- SP 2018: 23,861 orders, 23,284 buyers (44.1% of buyers), 2,975,612.23 sales (40.3%). 27 buyer states.
SELECT COALESCE(C.customer_state, 'ALL STATES') AS customer_state,
       COUNT(DISTINCT CASE WHEN YEAR(O.order_purchase_timestamp) = 2017
             THEN O.order_id END) AS orders_2017,
       COUNT(DISTINCT CASE WHEN YEAR(O.order_purchase_timestamp) = 2018
             THEN O.order_id END) AS orders_2018,
       COUNT(DISTINCT CASE WHEN YEAR(O.order_purchase_timestamp) = 2017
             THEN C.customer_unique_id END) AS buyers_2017,
       COUNT(DISTINCT CASE WHEN YEAR(O.order_purchase_timestamp) = 2018
             THEN C.customer_unique_id END) AS buyers_2018,
       SUM(CASE WHEN YEAR(O.order_purchase_timestamp) = 2017
             THEN ISNULL(OI.price, 0) ELSE 0 END) AS sales_2017,
       SUM(CASE WHEN YEAR(O.order_purchase_timestamp) = 2018
             THEN ISNULL(OI.price, 0) ELSE 0 END) AS sales_2018
FROM orders AS O
INNER JOIN customers AS C ON C.customer_id = O.customer_id
LEFT JOIN order_items AS OI ON OI.order_id = O.order_id
WHERE YEAR(O.order_purchase_timestamp) IN (2017, 2018)
  AND MONTH(O.order_purchase_timestamp) BETWEEN 1 AND 8
GROUP BY ROLLUP (C.customer_state)
ORDER BY GROUPING(C.customer_state), sales_2018 DESC;
GO

-- QUERY 3. Where do the item sales of SP sellers go? (item sales by buyer state)
-- Checks: total = SP seller sales of episode 13: 2,016,153.52 | 4,798,484.69.
-- SP buyers: 780,959.47 | 2,093,452.88 = 38.7% | 43.6% of SP seller sales; the rest (61.3% | 56.4%) goes to other states.
SELECT COALESCE(C.customer_state, 'ALL BUYER STATES') AS buyer_state,
       SUM(CASE WHEN YEAR(O.order_purchase_timestamp) = 2017
                THEN OI.price ELSE 0 END) AS sales_2017,
       SUM(CASE WHEN YEAR(O.order_purchase_timestamp) = 2018
                THEN OI.price ELSE 0 END) AS sales_2018
FROM order_items AS OI
INNER JOIN orders AS O ON O.order_id = OI.order_id
INNER JOIN customers AS C ON C.customer_id = O.customer_id
INNER JOIN sellers AS S ON S.seller_id = OI.seller_id
WHERE S.seller_state = 'SP'
  AND YEAR(O.order_purchase_timestamp) IN (2017, 2018)
  AND MONTH(O.order_purchase_timestamp) BETWEEN 1 AND 8
GROUP BY ROLLUP (C.customer_state)
ORDER BY GROUPING(C.customer_state), sales_2018 DESC;
GO

-- QUERY 4. Where do the purchases of each buyer state come from? (own state / SP / other states)
-- Checks: for every row, from_own_state + from_sp + from_other_states = total_sales; year totals = 3,113,000.32 | 7,385,905.80;
--         SP 2018 from_own_state = 2,093,452.88 (query 3). For SP buyers, from_sp is 0 by construction.
-- Reading (2018): SP buyers get 70.4% of purchases from SP sellers; all buyers outside SP: 61.3% of purchase value from SP sellers
--   (2,705,031.81 of 4,410,293.57) and 8.0% from their own state. These are shares of summed amounts, not averages of states.
SELECT YEAR(O.order_purchase_timestamp) AS yr,
       C.customer_state AS buyer_state,
       SUM(OI.price) AS total_sales,
       SUM(CASE WHEN S.seller_state = C.customer_state
                THEN OI.price ELSE 0 END) AS from_own_state,
       SUM(CASE WHEN S.seller_state = 'SP' AND C.customer_state <> 'SP'
                THEN OI.price ELSE 0 END) AS from_sp,
       SUM(CASE WHEN S.seller_state <> C.customer_state AND S.seller_state <> 'SP'
                THEN OI.price ELSE 0 END) AS from_other_states,
       ROUND(100.0 * SUM(CASE WHEN S.seller_state = C.customer_state
                THEN OI.price ELSE 0 END) / SUM(OI.price), 1) AS pct_own_state,
       ROUND(100.0 * SUM(CASE WHEN S.seller_state = 'SP' AND C.customer_state <> 'SP'
                THEN OI.price ELSE 0 END) / SUM(OI.price), 1) AS pct_from_sp
FROM order_items AS OI
INNER JOIN orders AS O ON O.order_id = OI.order_id
INNER JOIN customers AS C ON C.customer_id = O.customer_id
INNER JOIN sellers AS S ON S.seller_id = OI.seller_id
WHERE YEAR(O.order_purchase_timestamp) IN (2017, 2018)
  AND MONTH(O.order_purchase_timestamp) BETWEEN 1 AND 8
GROUP BY YEAR(O.order_purchase_timestamp), C.customer_state
ORDER BY yr, total_sales DESC;
GO

-- QUERY 5. Customer city names: are they usable as recorded?
-- Result: 3,946 city+state pairs before and after trimming and lower-casing; 3,788 city names alone (158 fewer: same name in different states).
-- Apostrophes in 27 names (santa barbara d'oeste, dias d'avila...) are legitimate. No digits, no accents. City = city + state pair.
SELECT COUNT(DISTINCT C.customer_state + '|' + C.customer_city) AS pairs_raw,
       COUNT(DISTINCT C.customer_state + '|' + LOWER(LTRIM(RTRIM(C.customer_city)))) AS pairs_trim_lower,
       COUNT(DISTINCT C.customer_city) AS city_names_only
FROM orders AS O
INNER JOIN customers AS C ON C.customer_id = O.customer_id
WHERE YEAR(O.order_purchase_timestamp) IN (2017, 2018)
  AND MONTH(O.order_purchase_timestamp) BETWEEN 1 AND 8;
GO

-- QUERY 6. Top buyer city per state and year (share of the state's distinct buyers).
-- Checks: state_buyers = buyers of query 2 (SP 8,696 | 23,284). SP: 465 | 561 cities, sao paulo 35.7% | 38.2%.
-- In all 27 states the top city is the state capital. Small bases: AM, AP, AC, RR (5 cities or fewer), DF has one city.
;WITH base AS (
    SELECT YEAR(O.order_purchase_timestamp) AS yr,
           C.customer_state AS st,
           LOWER(LTRIM(RTRIM(C.customer_city))) AS city,
           C.customer_unique_id AS buyer
    FROM orders AS O
    INNER JOIN customers AS C ON C.customer_id = O.customer_id
    WHERE YEAR(O.order_purchase_timestamp) IN (2017, 2018)
      AND MONTH(O.order_purchase_timestamp) BETWEEN 1 AND 8
), city_b AS (
    SELECT yr, st, city, COUNT(DISTINCT buyer) AS buyers
    FROM base
    GROUP BY yr, st, city
), state_b AS (
    SELECT yr, st, COUNT(DISTINCT buyer) AS state_buyers
    FROM base
    GROUP BY yr, st
), ranked AS (
    SELECT yr, st, city, buyers,
           ROW_NUMBER() OVER (PARTITION BY yr, st ORDER BY buyers DESC, city) AS rk,
           COUNT(*) OVER (PARTITION BY yr, st) AS cities
    FROM city_b
)
SELECT R.yr, R.st AS buyer_state, S.state_buyers, R.cities,
       R.city AS top_city, R.buyers AS top_city_buyers,
       ROUND(100.0 * R.buyers / S.state_buyers, 1) AS top_city_share_pct
FROM ranked AS R
INNER JOIN state_b AS S ON S.yr = R.yr AND S.st = R.st
WHERE R.rk = 1
ORDER BY R.yr, S.state_buyers DESC;
GO

-- QUERY 7. How many SP cities hold 50% and 80% of SP buyers? Change the year (2017, then 2018).
-- Results: 2017 = 465 cities, total 8,699, 8 cities (> 50%), 65 cities (80%) | 2018 = 561 cities, total 23,301, 6 cities, 55 cities.
-- total_buyers is the SUM of city counts: it is 3 (2017) and 17 (2018) above the distinct SP buyers (8,696 | 23,284).
;WITH base AS (
    SELECT LOWER(LTRIM(RTRIM(C.customer_city))) AS city,
           C.customer_unique_id AS buyer
    FROM orders AS O
    INNER JOIN customers AS C ON C.customer_id = O.customer_id
    WHERE YEAR(O.order_purchase_timestamp) = 2018      -- 2017 or 2018
      AND MONTH(O.order_purchase_timestamp) BETWEEN 1 AND 8
      AND C.customer_state = 'SP'
), city_b AS (
    SELECT city, COUNT(DISTINCT buyer) AS buyers
    FROM base
    GROUP BY city
), ranked AS (
    SELECT city, buyers,
           ROW_NUMBER() OVER (ORDER BY buyers DESC, city) AS rk,
           SUM(buyers) OVER (ORDER BY buyers DESC, city
                             ROWS UNBOUNDED PRECEDING) AS cum_buyers,
           SUM(buyers) OVER () AS total_buyers
    FROM city_b
)
SELECT COUNT(*) AS cities,
       MAX(total_buyers) AS total_buyers,
       MIN(CASE WHEN cum_buyers > 0.5 * total_buyers THEN rk END) AS cities_for_over_50pct,
       MIN(CASE WHEN cum_buyers >= 0.8 * total_buyers THEN rk END) AS cities_for_80pct
FROM ranked;
GO

-- QUERY 8. Robustness of the thresholds of query 7 (2018) against the 17 extra counts.
-- Unique buyers covered by the top k cities are between (cum_buyers - 17) and cum_buyers, out of 23,284 distinct SP buyers.
-- Result: rank 5 upper bound 48.62% (< 50) | rank 6 lower bound 50.31% (> 50)
--         rank 54 upper bound 79.94% (< 80) | rank 55 lower bound 80.12% (> 80). The thresholds 6 and 55 hold in the worst case.
;WITH base AS (
    SELECT LOWER(LTRIM(RTRIM(C.customer_city))) AS city,
           C.customer_unique_id AS buyer
    FROM orders AS O
    INNER JOIN customers AS C ON C.customer_id = O.customer_id
    WHERE YEAR(O.order_purchase_timestamp) = 2018
      AND MONTH(O.order_purchase_timestamp) BETWEEN 1 AND 8
      AND C.customer_state = 'SP'
), city_b AS (
    SELECT city, COUNT(DISTINCT buyer) AS buyers
    FROM base
    GROUP BY city
), ranked AS (
    SELECT city, buyers,
           ROW_NUMBER() OVER (ORDER BY buyers DESC, city) AS rk,
           SUM(buyers) OVER (ORDER BY buyers DESC, city
                             ROWS UNBOUNDED PRECEDING) AS cum_buyers
    FROM city_b
)
SELECT rk, city, buyers, cum_buyers,
       ROUND(100.0 * cum_buyers / 23284, 2) AS cum_pct_upper,
       ROUND(100.0 * (cum_buyers - 17) / 23284, 2) AS cum_pct_lower
FROM ranked
WHERE rk IN (5, 6, 54, 55)
ORDER BY rk;
GO
