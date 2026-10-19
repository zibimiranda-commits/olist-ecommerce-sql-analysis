-- Chapter 1 | Episode 8: Where Were the Sellers?
-- Follow-up to 13_seller_continuity.sql; SQL Server, read-only. No data is modified or corrected.
-- Windows: January-August 2017 vs January-August 2018 (purchase timestamps).
-- Item sales = SUM(order_items.price), freight excluded, NO order-status filter.
-- This is not Olist's official revenue. A seller is "active" with at least one item sold in the window.
-- Geography = the seller's REGISTERED state (sellers.seller_state). It says nothing about buyer location.
-- Regions (analyst grouping): Southeast = SP, MG, RJ, ES; South = PR, SC, RS; everything else = Other regions.
-- Queries 1-3 results were executed in SSMS by the analyst on 18-19 Oct 2026 and tie to the validated totals.
USE olist;
GO

-- 1. Business question: where were the active sellers registered?
-- Result: Southeast 909 | 1,752   South 267 | 513   Other regions 51 | 118
-- Totals: 1,227 (2017) and 2,383 (2018). Southeast + South = 95.8% (2017) and 95.0% (2018).
;WITH seller_windows AS (
    SELECT
        OI.seller_id,
        SUM(CASE WHEN YEAR(O.order_purchase_timestamp) = 2017
                 THEN OI.price ELSE 0 END) AS sales_2017,
        SUM(CASE WHEN YEAR(O.order_purchase_timestamp) = 2018
                 THEN OI.price ELSE 0 END) AS sales_2018
    FROM order_items AS OI
    INNER JOIN orders AS O
        ON O.order_id = OI.order_id
    WHERE YEAR(O.order_purchase_timestamp) IN (2017, 2018)
      AND MONTH(O.order_purchase_timestamp) BETWEEN 1 AND 8
    GROUP BY OI.seller_id
)
SELECT
    CASE WHEN S.seller_state IN ('SP','MG','RJ','ES') THEN 'Southeast'
         WHEN S.seller_state IN ('PR','SC','RS')      THEN 'South'
         ELSE 'Other regions' END AS region,
    SUM(CASE WHEN W.sales_2017 > 0 THEN 1 ELSE 0 END) AS sellers_2017,
    SUM(CASE WHEN W.sales_2018 > 0 THEN 1 ELSE 0 END) AS sellers_2018
FROM seller_windows AS W
INNER JOIN sellers AS S
    ON S.seller_id = W.seller_id
GROUP BY
    CASE WHEN S.seller_state IN ('SP','MG','RJ','ES') THEN 'Southeast'
         WHEN S.seller_state IN ('PR','SC','RS')      THEN 'South'
         ELSE 'Other regions' END
ORDER BY sellers_2018 DESC;

-- 2. Business question: does each registered state match the state suggested by the seller's ZIP prefix?
-- Reference rule: for each ZIP prefix, the most frequent state in the geolocation table
-- (ties broken by state code). This is an INTERNAL CONSISTENCY check, not address verification.
-- No state was corrected.
-- Result: CONSISTENT 3,053 | 3,090,181.71 | 7,343,840.15
--         INCONSISTENT 35 | 16,859.70 | 29,983.69
--         NOT_FOUND 7 | 5,958.91 | 12,081.96
-- Sales tie to 3,113,000.32 (2017) and 7,385,905.80 (2018). Flagged: 42 of 3,095 sellers (1.4%),
-- i.e. 0.73% of 2017 and 0.57% of 2018 item sales. Of the 35 inconsistent sellers, 33 were registered in SP.
;WITH zip_state_count AS (
    SELECT geolocation_zip_code_prefix, geolocation_state, COUNT(*) AS nb_occurences
    FROM geolocation
    GROUP BY geolocation_zip_code_prefix, geolocation_state
), zip_state_ranked AS (
    SELECT geolocation_zip_code_prefix, geolocation_state, nb_occurences,
           ROW_NUMBER() OVER (
               PARTITION BY geolocation_zip_code_prefix
               ORDER BY nb_occurences DESC, geolocation_state
           ) AS rang
    FROM zip_state_count
), seller_geographic_check AS (
    SELECT S.seller_id, S.seller_state, Z.geolocation_state AS reference_state,
           CASE WHEN Z.geolocation_state IS NULL THEN 'NOT_FOUND'
                WHEN S.seller_state = Z.geolocation_state THEN 'CONSISTENT'
                ELSE 'INCONSISTENT' END AS geographic_status
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
)
SELECT G.geographic_status,
       COUNT(*)                         AS sellers,
       SUM(ISNULL(S.sales_2017, 0))     AS sales_2017,
       SUM(ISNULL(S.sales_2018, 0))     AS sales_2018
FROM seller_geographic_check AS G
LEFT JOIN seller_sales AS S ON S.seller_id = G.seller_id
GROUP BY G.geographic_status
ORDER BY G.geographic_status;
-- COUNT(*) is a seller count because the sellers table has one row per seller (3,095 rows, 3,095 distinct IDs).

-- 3. Business question: is a city label a city?
-- First query: 611 distinct raw labels and 611 after LOWER/LTRIM/RTRIM. SQL Server's default comparison
-- ignores case and trailing spaces, so this does not prove that case is clean; it shows that basic
-- normalisation removes nothing and the differences are real spellings.
-- Second query (18 labels): "sao paulo" (694 sellers) plus six other spellings of the city of Sao Paulo
-- ("sp" 4, "sao paulo - sp" 3, "sao paulo / sao paulo" 1, "sao paulo sp" 1, "sao paulop" 1, "sp / sp" 1)
-- = 7 spellings and 705 sellers. Reading "sp" as the city of Sao Paulo is an interpretation.
-- Nine other cities hide behind "sao paulo" or "sp" (auriflama/sp, carapicuiba / sao paulo,
-- jacarei / sao paulo, maua/sao paulo, mogi das cruzes / sp, ribeirao preto / sao paulo,
-- santo andre/sao paulo, sao sebastiao da grama/sp, sbc/sp). "gaspar" (SC) and "vespasiano" (MG)
-- only contain "sp". A rule such as "any label containing sao paulo becomes Sao Paulo" would merge the nine.
SELECT COUNT(DISTINCT seller_city) AS raw_labels,
       COUNT(DISTINCT LOWER(LTRIM(RTRIM(seller_city)))) AS trimmed_lowercase_labels
FROM sellers;

SELECT seller_city, seller_state, COUNT(*) AS sellers
FROM sellers
WHERE seller_city LIKE '%sao paulo%'
   OR seller_city LIKE '%sp%'
GROUP BY seller_city, seller_state
ORDER BY sellers DESC, seller_city;
