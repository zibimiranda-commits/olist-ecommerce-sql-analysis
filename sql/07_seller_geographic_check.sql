-- Recovered/reconstructed from the analysis conversation.
-- Corrected/reconstructed from b9ef94e1 and the confirmed status summary; no data correction.
-- Prepared for SQL Server; NOT executed against SQL Server during recovery.
-- Read-only. Compare a fresh run with the recovered results before publication.
USE olist;
GO

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
    SELECT S.seller_id, S.seller_zip_code_prefix, S.seller_state,
           Z.geolocation_state AS reference_state,
           CASE WHEN Z.geolocation_state IS NULL THEN 'NOT_FOUND'
                WHEN S.seller_state = Z.geolocation_state THEN 'CONSISTENT'
                ELSE 'INCONSISTENT' END AS geographic_status
    FROM sellers AS S
    LEFT JOIN zip_state_ranked AS Z
      ON S.seller_zip_code_prefix = Z.geolocation_zip_code_prefix AND Z.rang = 1
)
SELECT geographic_status, COUNT(*) AS sellers
FROM seller_geographic_check
GROUP BY geographic_status
ORDER BY geographic_status;
-- For detail, replace the final SELECT with SELECT * FROM seller_geographic_check.
-- COUNT(*) is a seller count only if the sellers table has one row per seller.
-- This reproduces the historical internal-reference rule, including how nulls
-- are ranked; it does not independently validate addresses or correct states.
