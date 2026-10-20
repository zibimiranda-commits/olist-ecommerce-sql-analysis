-- Chapter 2 | Steps 2-3: robustness checks and seller geography (Sao Paulo)
-- SQL Server, read-only. No data is modified.
-- Windows: January-August 2017 vs January-August 2018 (purchase timestamps).
-- Item sales = SUM(order_items.price), freight excluded, NO order-status filter (Chapter 1 definition), unless a
-- query says otherwise. This is not Olist's official revenue. Descriptive comparisons: they do not establish causes.
-- Geography = the seller's REGISTERED location; "city" uses the mapping table of 17_seller_city_map.sql
-- (run that script first). Unresolved city labels are excluded from city groups.
-- Results were executed in SSMS by the analyst on 20 Oct 2026; every result ties to R$ 3,113,000.32 and
-- R$ 7,385,905.80 (total item sales) unless stated otherwise.
USE olist;
GO

-- 1. Does the Sao Paulo share change if the state is taken from the ZIP prefix instead of the registered state?
-- ZIP-based state = most frequent state per ZIP prefix (ties broken by state code), as in Episode 8.
-- When the ZIP prefix is not found, the registered state is kept.
-- Result: totals 3,113,000.32 | 7,385,905.80 (tie)
--   SP sales, registered state: 2,016,153.52 | 4,798,484.69 -> 64.77% | 64.97% of item sales
--   SP sales, ZIP-based state:  1,999,293.82 | 4,768,791.00 -> 64.22% | 64.57%
--   Share of the 2017-2018 increase: 65.12% (registered) vs 64.82% (ZIP-based)
-- Reading: taking the ZIP-based state lowers SP's share by 0.55 point (2017) and 0.40 point (2018); the
-- "about 65%" holds either way. The ZIP-based state is a scenario, not a correction.
;WITH zip_state_count AS (
    SELECT geolocation_zip_code_prefix, geolocation_state, COUNT(*) AS nb_occurences
    FROM geolocation
    GROUP BY geolocation_zip_code_prefix, geolocation_state
), zip_state_ranked AS (
    SELECT geolocation_zip_code_prefix, geolocation_state,
           ROW_NUMBER() OVER (
               PARTITION BY geolocation_zip_code_prefix
               ORDER BY nb_occurences DESC, geolocation_state
           ) AS rang
    FROM zip_state_count
), seller_states AS (
    SELECT S.seller_id,
           S.seller_state AS state_registered,
           COALESCE(Z.geolocation_state, S.seller_state) AS state_zip_ref
    FROM sellers AS S
    LEFT JOIN zip_state_ranked AS Z
      ON S.seller_zip_code_prefix = Z.geolocation_zip_code_prefix AND Z.rang = 1
), seller_sales AS (
    SELECT OI.seller_id,
           SUM(CASE WHEN YEAR(O.order_purchase_timestamp) = 2017 THEN OI.price ELSE 0 END) AS sales_2017,
           SUM(CASE WHEN YEAR(O.order_purchase_timestamp) = 2018 THEN OI.price ELSE 0 END) AS sales_2018
    FROM order_items AS OI
    INNER JOIN orders AS O ON O.order_id = OI.order_id
    WHERE YEAR(O.order_purchase_timestamp) IN (2017, 2018)
      AND MONTH(O.order_purchase_timestamp) BETWEEN 1 AND 8
    GROUP BY OI.seller_id
), agg AS (
    SELECT
        SUM(SS.sales_2017) AS total_2017,
        SUM(SS.sales_2018) AS total_2018,
        SUM(CASE WHEN X.state_registered = 'SP' THEN SS.sales_2017 ELSE 0 END) AS sp_reg_2017,
        SUM(CASE WHEN X.state_registered = 'SP' THEN SS.sales_2018 ELSE 0 END) AS sp_reg_2018,
        SUM(CASE WHEN X.state_zip_ref   = 'SP' THEN SS.sales_2017 ELSE 0 END) AS sp_zip_2017,
        SUM(CASE WHEN X.state_zip_ref   = 'SP' THEN SS.sales_2018 ELSE 0 END) AS sp_zip_2018
    FROM seller_states AS X
    INNER JOIN seller_sales AS SS ON SS.seller_id = X.seller_id
)
SELECT total_2017, total_2018,
       sp_reg_2017, sp_zip_2017, sp_reg_2018, sp_zip_2018,
       ROUND(100.0 * sp_reg_2017 / total_2017, 2) AS share_2017_registered,
       ROUND(100.0 * sp_zip_2017 / total_2017, 2) AS share_2017_zip_ref,
       ROUND(100.0 * sp_reg_2018 / total_2018, 2) AS share_2018_registered,
       ROUND(100.0 * sp_zip_2018 / total_2018, 2) AS share_2018_zip_ref,
       ROUND(100.0 * (sp_reg_2018 - sp_reg_2017) / (total_2018 - total_2017), 2) AS share_of_increase_registered,
       ROUND(100.0 * (sp_zip_2018 - sp_zip_2017) / (total_2018 - total_2017), 2) AS share_of_increase_zip_ref
FROM agg;

-- 2. Where do the sellers registered in SP but pointing elsewhere go? (and does any seller move INTO SP?)
-- Result: 8 rows, all with registered state SP; no seller registered elsewhere points to SP.
--   ZIP state PR 10 sellers (4,543.78 | 3,861.15), SC 7 (2,233.22 | 4,236.41), MG 6 (3,334.60 | 17,851.95),
--   RJ 4 (6,393.30 | 1,390.38), RS 3 (229.90 | 1,011.80), DF 1 (35.00 | 0.00), BA 1 (0.00 | 1,342.00),
--   ES 1 (89.90 | 0.00).  Total 33 sellers, R$ 16,859.70 (2017) and R$ 29,693.69 (2018).
-- Ties: 33 = SP-registered INCONSISTENT sellers of Episode 8; 16,859.70 = Episode 8 INCONSISTENT 2017 sales;
-- 29,693.69 = the drop in SP sales of query 1. The 290.00 gap to Episode 8's 29,983.69 (2018) belongs to the 2
-- INCONSISTENT sellers registered outside SP (35 - 33), by subtraction.
;WITH zip_state_count AS (
    SELECT geolocation_zip_code_prefix, geolocation_state, COUNT(*) AS nb_occurences
    FROM geolocation
    GROUP BY geolocation_zip_code_prefix, geolocation_state
), zip_state_ranked AS (
    SELECT geolocation_zip_code_prefix, geolocation_state,
           ROW_NUMBER() OVER (
               PARTITION BY geolocation_zip_code_prefix
               ORDER BY nb_occurences DESC, geolocation_state
           ) AS rang
    FROM zip_state_count
), seller_sales AS (
    SELECT OI.seller_id,
           SUM(CASE WHEN YEAR(O.order_purchase_timestamp) = 2017 THEN OI.price ELSE 0 END) AS sales_2017,
           SUM(CASE WHEN YEAR(O.order_purchase_timestamp) = 2018 THEN OI.price ELSE 0 END) AS sales_2018
    FROM order_items AS OI
    INNER JOIN orders AS O ON O.order_id = OI.order_id
    WHERE YEAR(O.order_purchase_timestamp) IN (2017, 2018)
      AND MONTH(O.order_purchase_timestamp) BETWEEN 1 AND 8
    GROUP BY OI.seller_id
)
SELECT S.seller_state AS state_registered,
       Z.geolocation_state AS state_zip_ref,
       COUNT(*) AS sellers,
       SUM(ISNULL(SS.sales_2017, 0)) AS sales_2017,
       SUM(ISNULL(SS.sales_2018, 0)) AS sales_2018
FROM sellers AS S
INNER JOIN zip_state_ranked AS Z
   ON S.seller_zip_code_prefix = Z.geolocation_zip_code_prefix AND Z.rang = 1
LEFT JOIN seller_sales AS SS ON SS.seller_id = S.seller_id
WHERE S.seller_state <> Z.geolocation_state
  AND (S.seller_state = 'SP' OR Z.geolocation_state = 'SP')
GROUP BY S.seller_state, Z.geolocation_state
ORDER BY sellers DESC;

-- 3. Order-status control: how much of the item sales comes from delivered orders?
-- Orders without items (for example some canceled or unavailable orders) are kept through a LEFT JOIN and
-- contribute 0 to sales. Status is as recorded in the dataset; no reason is inferred.
-- Result (orders 2017 | 2018, item sales 2017 | 2018):
--   delivered    21,998 | 52,783   2,993,456.13 | 7,218,125.12
--   shipped         330 |    567      40,749.65 |    82,949.62
--   canceled        171 |    315      32,149.51 |    44,868.39
--   invoiced         94 |    121      15,848.46 |    30,798.16
--   processing      138 |     59      30,586.97 |     9,164.51
--   created           0 |      1           0.00 |         0.00
--   unavailable     235 |    145           0.00 |         0.00
--   approved          2 |      0         209.60 |         0.00
-- Ties: orders sum to 22,968 and 53,991; sales sum to 3,113,000.32 and 7,385,905.80.
-- Reading: delivered orders are 95.8% (2017) and 97.8% (2018) of orders and 96.2% and 97.7% of item sales.
-- Item sales rose 137.3% over all statuses and 141.1% over delivered orders only (orders: +135.1% and +140.0%).
-- The doubling does not depend on the missing status filter. Non-delivered orders: 970 (4.2%) in 2017 and
-- 1,208 (2.2%) in 2018; 330 orders of 2017 still show "shipped" (reason unknown).
SELECT O.order_status,
       COUNT(DISTINCT CASE WHEN YEAR(O.order_purchase_timestamp) = 2017 THEN O.order_id END) AS orders_2017,
       COUNT(DISTINCT CASE WHEN YEAR(O.order_purchase_timestamp) = 2018 THEN O.order_id END) AS orders_2018,
       SUM(CASE WHEN YEAR(O.order_purchase_timestamp) = 2017 THEN ISNULL(OI.price, 0) ELSE 0 END) AS sales_2017,
       SUM(CASE WHEN YEAR(O.order_purchase_timestamp) = 2018 THEN ISNULL(OI.price, 0) ELSE 0 END) AS sales_2018
FROM orders AS O
LEFT JOIN order_items AS OI ON OI.order_id = O.order_id
WHERE YEAR(O.order_purchase_timestamp) IN (2017, 2018)
  AND MONTH(O.order_purchase_timestamp) BETWEEN 1 AND 8
GROUP BY O.order_status
ORDER BY sales_2018 DESC;

-- 4. How much of the sellers and of the sales is the city of Sao Paulo, versus the rest of the state?
-- Four groups that partition the sellers (city from the mapping table; unresolved labels form their own group).
-- Result (active sellers 2017 | 2018, item sales 2017 | 2018):
--   1. SP state - Sao Paulo city      289 |   522     640,912.71 | 1,488,974.01
--   2. SP state - city unresolved       4 |     8       2,372.36 |    27,063.56
--   3. SP state - other cities        430 |   887   1,372,868.45 | 3,282,447.12
--   4. Other states                   504 |   966   1,096,846.80 | 2,587,421.11
-- Ties: sellers 1,227 and 2,383; sales 3,113,000.32 and 7,385,905.80; groups 1-3 = SP state (723 and 1,417
-- sellers; R$ 2,016,153.52 and R$ 4,798,484.69).
-- Reading: the city of Sao Paulo is 23.6% -> 21.9% of active sellers and 20.6% -> 20.2% of item sales and
-- 19.85% of the increase; the other cities of the state are 35.0% -> 37.2% of sellers, 44.1% -> 44.4% of sales
-- and 44.69% of the increase; other states 34.88% of the increase; unresolved 0.58% (SP state total 65.12%).
-- Mean item sales per active seller (mean only; medians still to compute): city of Sao Paulo 2,217.69 -> 2,852.44;
-- other SP cities 3,192.72 -> 3,700.62; other states 2,176.28 -> 2,678.49.
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
                ELSE COALESCE(M.clean_city, S.seller_city) END AS city_clean
    FROM sellers AS S
    LEFT JOIN dbo.seller_city_map AS M
           ON M.raw_city = S.seller_city
          AND (M.raw_state IS NULL OR M.raw_state = S.seller_state)
)
SELECT
    CASE WHEN G.seller_state = 'SP' AND G.city_clean = 'sao paulo' THEN '1. SP state - Sao Paulo city'
         WHEN G.seller_state = 'SP' AND G.city_clean IS NULL       THEN '2. SP state - city unresolved'
         WHEN G.seller_state = 'SP'                                THEN '3. SP state - other cities'
         ELSE '4. Other states' END AS seller_group,
    SUM(CASE WHEN SS.sales_2017 > 0 THEN 1 ELSE 0 END) AS sellers_2017,
    SUM(CASE WHEN SS.sales_2018 > 0 THEN 1 ELSE 0 END) AS sellers_2018,
    SUM(SS.sales_2017) AS sales_2017,
    SUM(SS.sales_2018) AS sales_2018
FROM seller_geo AS G
INNER JOIN seller_sales AS SS ON SS.seller_id = G.seller_id
GROUP BY
    CASE WHEN G.seller_state = 'SP' AND G.city_clean = 'sao paulo' THEN '1. SP state - Sao Paulo city'
         WHEN G.seller_state = 'SP' AND G.city_clean IS NULL       THEN '2. SP state - city unresolved'
         WHEN G.seller_state = 'SP'                                THEN '3. SP state - other cities'
         ELSE '4. Other states' END
ORDER BY seller_group;

-- 5. Which cities contributed most to the increase in item sales?
-- Result: the top 15 cities account for R$ 2,311,682.66 of the R$ 4,272,905.48 increase (54.1%); 10 of them are in
-- the state of SP (about 41.5% of the increase), plus Curitiba and Maringa (PR), Rio de Janeiro and Teresopolis
-- (RJ) and Recife (PE).
--   Sao Paulo (SP)  289 -> 522 sellers  640,912.71 -> 1,488,974.01   increase 848,061.30  19.85%  (tie with query 4)
--   Guarulhos (SP)   15 ->  42          57,001.14 ->   238,422.88              181,421.74   4.25%
--   Curitiba (PR)    61 ->  91         104,371.10 ->   259,245.45              154,874.35   3.62%
--   Ribeirao Preto (SP) 21 -> 42        64,669.09 ->   209,901.74              145,232.65   3.40%
--   Sao Bernardo do Campo (SP) 10 -> 31 15,733.56 ->   128,931.71              113,198.15   2.65%
--   Guariba (SP)      1 ->   1         25,646.93 ->   138,414.60              112,767.67   2.64%
--   Teresopolis (RJ)  0 ->   2              0.00 ->   111,913.09              111,913.09   2.62%
--   Maringa (PR)     14 ->  34         29,836.94 ->   140,904.46              111,067.52   2.60%
--   Ibitinga (SP)    15 ->  45        180,538.34 ->   289,559.28              109,020.94   2.55%
--   Rio de Janeiro (RJ) 36 -> 75       83,292.31 ->   168,493.19               85,200.88   1.99%
--   Campinas (SP)    18 ->  29         38,301.05 ->   120,674.38               82,373.33   1.93%
--   Recife (PE)       1 ->   4          3,198.00 ->    80,032.00               76,834.00   1.80%
--   Diadema (SP)      0 ->   9              0.00 ->    67,598.73               67,598.73   1.58%
--   Salto (SP)        3 ->   8         26,016.30 ->    84,039.10               58,022.80   1.36%
--   Sumare (SP)       2 ->   4         42,583.79 ->    96,679.30               54,095.51   1.27%
-- Reading: the growth is spread over several cities of the state of SP. A city can depend on very few sellers
-- (Guariba: one active seller in each window, 2.64% of the increase; Teresopolis: no recorded sale in 2017 and
-- two sellers in 2018), so a ranking of cities is not a measure of city dynamics. Ibitinga added sellers faster
-- than sales: mean item sales per seller 12,036 -> 6,435 (means, influenced by a few large sellers).
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
                ELSE COALESCE(M.clean_city, S.seller_city) END AS city_clean
    FROM sellers AS S
    LEFT JOIN dbo.seller_city_map AS M
           ON M.raw_city = S.seller_city
          AND (M.raw_state IS NULL OR M.raw_state = S.seller_state)
), city_sales AS (
    SELECT G.seller_state, G.city_clean,
           SUM(CASE WHEN SS.sales_2017 > 0 THEN 1 ELSE 0 END) AS sellers_2017,
           SUM(CASE WHEN SS.sales_2018 > 0 THEN 1 ELSE 0 END) AS sellers_2018,
           SUM(SS.sales_2017) AS sales_2017,
           SUM(SS.sales_2018) AS sales_2018
    FROM seller_geo AS G
    INNER JOIN seller_sales AS SS ON SS.seller_id = G.seller_id
    WHERE G.city_clean IS NOT NULL
    GROUP BY G.seller_state, G.city_clean
)
SELECT TOP 15
       seller_state, city_clean,
       sellers_2017, sellers_2018, sales_2017, sales_2018,
       sales_2018 - sales_2017 AS increase,
       ROUND(100.0 * (sales_2018 - sales_2017)
             / (SELECT SUM(sales_2018) - SUM(sales_2017) FROM seller_sales), 2) AS pct_of_total_increase
FROM city_sales
ORDER BY (sales_2018 - sales_2017) DESC;
