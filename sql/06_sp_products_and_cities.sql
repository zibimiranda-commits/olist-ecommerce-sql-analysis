-- Separate queries used and rerun by the analyst in SSMS on 2026-10-15.
-- Formatting consolidated for the repository; no combined CTE is introduced.
-- Read-only; no order-status filter. See VERIFIED_RESULTS_2026_10_15.md.
USE olist;
GO

-- 11. SP raw city labels. Observed: 151 / 228; provisional while cleaning continues.
SELECT YEAR(O.order_purchase_timestamp) AS order_year,
       COUNT(DISTINCT S.seller_city) AS seller_city_labels
FROM sellers AS S
INNER JOIN order_items AS I ON S.seller_id = I.seller_id
INNER JOIN orders AS O ON I.order_id = O.order_id
WHERE S.seller_state = 'SP'
  AND YEAR(O.order_purchase_timestamp) IN (2017, 2018)
  AND MONTH(O.order_purchase_timestamp) BETWEEN 1 AND 8
GROUP BY YEAR(O.order_purchase_timestamp)
ORDER BY order_year;

-- Cleaning is ongoing. These are distinct recorded labels, not validated cities.
-- No reconstructed SP product-count or appearing-city query is included here.
