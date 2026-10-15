-- Recovered/reconstructed from the analysis conversation.
-- Raw city query corrected from 35ed8c56 (letter O instead of zero); SP product query reconstructed.
-- Prepared for SQL Server; NOT executed against SQL Server during recovery.
-- Read-only. Compare a fresh run with the recovered results before publication.
USE olist;
GO

-- Raw city labels; expected historical counts were 151 and 258, not validated municipalities.
SELECT YEAR(O.order_purchase_timestamp) AS order_year,
       COUNT(DISTINCT S.seller_city) AS city_sellers
FROM sellers AS S
INNER JOIN order_items AS I ON S.seller_id = I.seller_id
INNER JOIN orders AS O ON I.order_id = O.order_id
WHERE S.seller_state = 'SP'
  AND YEAR(O.order_purchase_timestamp) IN (2017, 2018)
  AND MONTH(O.order_purchase_timestamp) BETWEEN 1 AND 8
GROUP BY YEAR(O.order_purchase_timestamp);

-- Exact historical SP product counts are not recovered.
SELECT YEAR(O.order_purchase_timestamp) AS order_year,
       COUNT(DISTINCT I.product_id) AS sold_product_references
FROM sellers AS S
INNER JOIN order_items AS I ON S.seller_id = I.seller_id
INNER JOIN orders AS O ON I.order_id = O.order_id
INNER JOIN products AS P ON I.product_id = P.product_id
WHERE S.seller_state = 'SP'
  AND YEAR(O.order_purchase_timestamp) IN (2017, 2018)
  AND MONTH(O.order_purchase_timestamp) BETWEEN 1 AND 8
GROUP BY YEAR(O.order_purchase_timestamp);

-- Reconstructed list of appearing AND disappearing raw labels.
;WITH cities AS (
    SELECT DISTINCT YEAR(O.order_purchase_timestamp) AS order_year, S.seller_city
    FROM sellers AS S
    INNER JOIN order_items AS I ON S.seller_id = I.seller_id
    INNER JOIN orders AS O ON I.order_id = O.order_id
    WHERE S.seller_state = 'SP'
      AND YEAR(O.order_purchase_timestamp) IN (2017, 2018)
      AND MONTH(O.order_purchase_timestamp) BETWEEN 1 AND 8
      AND S.seller_city IS NOT NULL
)
SELECT C.seller_city, C.order_year AS only_in_year
FROM cities AS C
WHERE NOT EXISTS (
    SELECT 1 FROM cities AS P
    WHERE P.seller_city = C.seller_city AND P.order_year <> C.order_year
)
ORDER BY only_in_year, seller_city;
