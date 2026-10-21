-- Chapter 2 | Step 1: geography label audit (sellers and customers)
-- SQL Server, read-only. No data is modified or corrected by this script.
-- Purpose: measure how clean the city labels are before any city-level analysis, and compare them with the ZIP reference.
-- ZIP reference rule: for each ZIP prefix, the most frequent (city, state) pair in the geolocation table
-- (ties broken by name). This is an INTERNAL CONSISTENCY check, not address verification. The geolocation table
-- itself contains encoding artefacts and spelling variants, so a match is not proof of a correct label and a
-- mismatch is not proof of an error.
-- Results were executed in SSMS by the analyst on 20 Oct 2026 and cross-checked arithmetically.
-- Query 6 reads the mapping table created by 17_seller_city_map.sql: run that script first.
USE olist;
GO

-- 1. How many city labels exist before any cleaning?
-- Result: sellers   3,095 rows | 611 raw labels | 611 after LOWER/LTRIM/RTRIM | 636 city+state pairs
--         customers 99,441 rows | 4,119 raw labels | 4,119 after LOWER/LTRIM/RTRIM | 4,310 city+state pairs
-- customers has one row per customer_id (one per order), not per unique buyer.
-- Basic normalisation does not reduce the count: it does not detect internal double spaces, and SQL Server's
-- default comparison already ignores case.
SELECT 'sellers' AS source,
       COUNT(*) AS rows_total,
       COUNT(DISTINCT seller_city) AS raw_labels,
       COUNT(DISTINCT LOWER(LTRIM(RTRIM(seller_city)))) AS trimmed_lowercase_labels,
       COUNT(DISTINCT seller_city + '|' + seller_state) AS city_state_pairs
FROM sellers
UNION ALL
SELECT 'customers',
       COUNT(*),
       COUNT(DISTINCT customer_city),
       COUNT(DISTINCT LOWER(LTRIM(RTRIM(customer_city)))),
       COUNT(DISTINCT customer_city + '|' + customer_state)
FROM customers;

-- 2. Which labels contain something other than letters and spaces?
-- Result: customers 54 labels, all genuine place names with apostrophes or hyphens (for example
--         santa barbara d'oeste 119, mogi-guacu 93, embu-guacu 46): nothing to clean, and a rule that
--         strips these characters would create false cities.
--         sellers 26 labels to treat (29 sellers) plus 2 genuine names (santa barbara d'oeste, sao miguel d'oeste):
--         city and state in the same field (for example "sao paulo - sp", "pinhais/pr"), a state or country
--         name added to the city, corrupted encoding (2 labels), one number and one e-mail address.
SELECT 'sellers' AS source, seller_city AS city_label, seller_state AS state, COUNT(*) AS n
FROM sellers
WHERE seller_city LIKE '%[^a-z ]%'
GROUP BY seller_city, seller_state
UNION ALL
SELECT 'customers', customer_city, customer_state, COUNT(*)
FROM customers
WHERE customer_city LIKE '%[^a-z ]%'
GROUP BY customer_city, customer_state
ORDER BY source, n DESC, city_label;

-- 3. Same city name registered under several states or spellings (customers)
-- Result: 163 names appear with 2 to 4 states (142 with 2, 14 with 3, 7 with 4); raw_spellings = 1 for every row,
--         so these are homonyms, not spelling variants.
-- Check: (142 x 1) + (14 x 2) + (7 x 3) = 191 = 4,310 - 4,119 (query 1). The extra pairs are fully explained.
-- Consequence: city must always be handled together with state.
SELECT LOWER(LTRIM(RTRIM(customer_city))) AS city_norm,
       COUNT(DISTINCT customer_state) AS states,
       COUNT(DISTINCT customer_city) AS raw_spellings,
       COUNT(*) AS customers
FROM customers
GROUP BY LOWER(LTRIM(RTRIM(customer_city)))
HAVING COUNT(DISTINCT customer_state) > 1
    OR COUNT(DISTINCT customer_city) > 1
ORDER BY customers DESC;

-- 4. Which (city, state) pairs do not exist in the geolocation reference?
-- Result: customers 60 labels (76 of 99,441 rows, 0.08%): small localities and districts, no obvious typo, left as is.
--         sellers   94 labels (103 of 3,095 sellers, 3.3%).
;WITH G AS (
    SELECT DISTINCT geolocation_city, geolocation_state
    FROM geolocation
)
SELECT 'sellers' AS source, S.seller_city AS city_label, S.seller_state AS state, COUNT(*) AS n
FROM sellers AS S
LEFT JOIN G ON G.geolocation_city = S.seller_city AND G.geolocation_state = S.seller_state
WHERE G.geolocation_city IS NULL
GROUP BY S.seller_city, S.seller_state
UNION ALL
SELECT 'customers', C.customer_city, C.customer_state, COUNT(*)
FROM customers AS C
LEFT JOIN G ON G.geolocation_city = C.customer_city AND G.geolocation_state = C.customer_state
WHERE G.geolocation_city IS NULL
GROUP BY C.customer_city, C.customer_state
ORDER BY source, n DESC, city_label;

-- 5. What does the seller's ZIP prefix say about those 103 sellers?
-- geolocation holds several rows per ZIP prefix, so the most frequent label is kept per prefix (ROW_NUMBER);
-- joining the raw table directly would multiply rows.
-- Result (103 sellers, classified by the analyst):
--   55  the city text is wrong (typo, state or country added, double space, encoding, hyphen, abbreviation);
--       state and ZIP reference agree
--   32  the city name agrees with the ZIP reference but the registered state differs (30 registered in SP)
--   14  not a usable city name (state name, number, e-mail address, generic word) or ambiguous
--    2  reference-table quirks (corrupted encoding in the reference, "d'oeste" vs "do oeste")
;WITH Z AS (
    SELECT geolocation_zip_code_prefix AS zip,
           geolocation_city  AS ref_city,
           geolocation_state AS ref_state,
           ROW_NUMBER() OVER (
               PARTITION BY geolocation_zip_code_prefix
               ORDER BY COUNT(*) DESC, geolocation_city
           ) AS rk
    FROM geolocation
    GROUP BY geolocation_zip_code_prefix, geolocation_city, geolocation_state
),
G AS (
    SELECT DISTINCT geolocation_city, geolocation_state
    FROM geolocation
)
SELECT S.seller_city, S.seller_state, S.seller_zip_code_prefix AS zip, Z.ref_city, Z.ref_state
FROM sellers AS S
LEFT JOIN G ON G.geolocation_city = S.seller_city AND G.geolocation_state = S.seller_state
LEFT JOIN Z ON Z.zip = S.seller_zip_code_prefix AND Z.rk = 1
WHERE G.geolocation_city IS NULL
ORDER BY S.seller_city;

-- 6. After applying the mapping table: which sellers still differ from the ZIP reference city?
-- Run after 17_seller_city_map.sql. First run of this check: 43 rows covering 53 sellers.
--   13  reference gaps or corrupted encoding in the reference (label looks valid): nothing to do
--    9  missing hyphen (mogi guacu 8, embu guacu 1) -> added to the mapping table
--    1  label missed in the first mapping version ("rio de janeiro, rio de janeiro, brasil") -> added
--    4  "sp" alone (not a city) -> added as unresolved
--   26  valid city label, but the ZIP prefix belongs to another municipality (12 "sao paulo", 4 "rio de janeiro",
--       2 "ribeirao preto", and others) -> label kept as registered and documented (rule 5)
-- This check was needed because the geolocation table also contains non-standard spellings (for example
-- "santa barbara d oeste"), so a label can pass query 4 without being the standard spelling.
;WITH Z AS (
    SELECT geolocation_zip_code_prefix AS zip,
           geolocation_city  AS ref_city,
           geolocation_state AS ref_state,
           ROW_NUMBER() OVER (
               PARTITION BY geolocation_zip_code_prefix
               ORDER BY COUNT(*) DESC, geolocation_city) AS rk
    FROM geolocation
    GROUP BY geolocation_zip_code_prefix, geolocation_city, geolocation_state
)
SELECT COALESCE(M.clean_city, S.seller_city) AS city_clean,
       S.seller_state, Z.ref_city, Z.ref_state, COUNT(*) AS sellers
FROM sellers AS S
LEFT JOIN dbo.seller_city_map AS M
       ON M.raw_city = S.seller_city AND (M.raw_state IS NULL OR M.raw_state = S.seller_state)
LEFT JOIN Z ON Z.zip = S.seller_zip_code_prefix AND Z.rk = 1
WHERE ISNULL(M.status, '') <> 'unresolved'
  AND (Z.ref_city IS NULL OR COALESCE(M.clean_city, S.seller_city) <> Z.ref_city)
GROUP BY COALESCE(M.clean_city, S.seller_city), S.seller_state, Z.ref_city, Z.ref_state
ORDER BY sellers DESC, city_clean;

-- 7. Summary of query 3: how many customer city names appear under 2, 3 or 4 states?
-- Result: 2 states = 142 names | 3 states = 14 | 4 states = 7 (total 163).
-- Check: 142 x 1 + 14 x 2 + 7 x 3 = 191 = 4,310 - 4,119 (query 1).
;WITH multi_state AS (
    SELECT LOWER(LTRIM(RTRIM(customer_city))) AS city_norm,
           COUNT(DISTINCT customer_state) AS states
    FROM customers
    GROUP BY LOWER(LTRIM(RTRIM(customer_city)))
    HAVING COUNT(DISTINCT customer_state) > 1
)
SELECT states,
       COUNT(*) AS city_names
FROM multi_state
GROUP BY states
ORDER BY states;

-- 8. Summary of query 4: how many city labels are absent from the ZIP reference?
-- Result: sellers 94 labels / 103 sellers (103 of 3,095 = 3.3%) | customers 60 labels / 76 rows (0.08% of 99,441).
;WITH ref AS (
    SELECT DISTINCT geolocation_city, geolocation_state
    FROM geolocation
),
missing_sellers AS (
    SELECT S.seller_city, S.seller_state, COUNT(*) AS n
    FROM sellers AS S
    LEFT JOIN ref ON ref.geolocation_city = S.seller_city
                 AND ref.geolocation_state = S.seller_state
    WHERE ref.geolocation_city IS NULL
    GROUP BY S.seller_city, S.seller_state
),
missing_customers AS (
    SELECT C.customer_city, C.customer_state, COUNT(*) AS n
    FROM customers AS C
    LEFT JOIN ref ON ref.geolocation_city = C.customer_city
                 AND ref.geolocation_state = C.customer_state
    WHERE ref.geolocation_city IS NULL
    GROUP BY C.customer_city, C.customer_state
)
SELECT 'sellers' AS source, COUNT(*) AS labels_not_found, SUM(n) AS rows_affected
FROM missing_sellers
UNION ALL
SELECT 'customers', COUNT(*), SUM(n)
FROM missing_customers;
