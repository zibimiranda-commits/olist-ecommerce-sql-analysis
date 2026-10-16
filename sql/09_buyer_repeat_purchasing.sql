-- Chapter 1 | Episode 3: Buyer Growth vs. Repeat Purchasing
-- Follow-up to 04_buyers_and_products.sql; SQL Server, read-only.
-- Results below were supplied as validated by the analyst; not rerun in this update.
-- Buyer identity: customers.customer_unique_id, linked via customer_id.
-- All queries use purchase timestamps and apply NO order-status filter.
-- Cancelled or undelivered orders may therefore be included.
USE olist;
GO

-- 1. Business question: Did buyer growth coincide with more repeat purchasing
-- within the same January-August window?
-- Validated results (order_year | frequency | buyers):
-- 2017 | 1  | 21733
-- 2017 | 2  |   537
-- 2017 | 3+ |    50
-- 2018 | 1  | 51586
-- 2018 | 2  |  1085
-- 2018 | 3+ |    72
-- Totals: 22320 and 52743 active buyers (+136.3%).
-- Single-order buyers: 97.37% in 2017 and 97.81% in 2018.
-- Limit: frequency is measured only within each eight-month window, not over
-- the buyer's lifetime. These counts establish neither causes of growth nor
-- measured loyalty; purchases outside each window are excluded.
;WITH buyer_orders AS (
    SELECT C.customer_unique_id,
           YEAR(O.order_purchase_timestamp) AS order_year,
           COUNT(DISTINCT O.order_id) AS order_count
    FROM customers AS C
    INNER JOIN orders AS O ON C.customer_id = O.customer_id
    WHERE YEAR(O.order_purchase_timestamp) IN (2017, 2018)
      AND MONTH(O.order_purchase_timestamp) BETWEEN 1 AND 8
    GROUP BY C.customer_unique_id, YEAR(O.order_purchase_timestamp)
)
SELECT order_year,
       CASE WHEN order_count = 1 THEN '1'
            WHEN order_count = 2 THEN '2'
            ELSE '3+' END AS order_frequency,
       COUNT(*) AS buyers
FROM buyer_orders
GROUP BY order_year,
         CASE WHEN order_count = 1 THEN '1'
              WHEN order_count = 2 THEN '2'
              ELSE '3+' END
ORDER BY order_year, order_frequency;

-- 2. Business question: How many buyers appear in BOTH January-August windows?
-- Validated result: 341 buyers.
-- Limit: this is overlap between two selected windows. It excludes buyers
-- observed only in September-December 2017 from the 2017 comparison group.
-- It is not the broader pre-2018 history check below, and does not establish
-- causes, a standard retention rate, or measured loyalty.
;WITH buyers_2017 AS (
    SELECT DISTINCT C.customer_unique_id
    FROM customers AS C
    INNER JOIN orders AS O ON C.customer_id = O.customer_id
    WHERE YEAR(O.order_purchase_timestamp) = 2017
      AND MONTH(O.order_purchase_timestamp) BETWEEN 1 AND 8
),
buyers_2018 AS (
    SELECT DISTINCT C.customer_unique_id
    FROM customers AS C
    INNER JOIN orders AS O ON C.customer_id = O.customer_id
    WHERE YEAR(O.order_purchase_timestamp) = 2018
      AND MONTH(O.order_purchase_timestamp) BETWEEN 1 AND 8
)
SELECT COUNT(*) AS buyers_in_both_windows
FROM buyers_2017 AS B17
INNER JOIN buyers_2018 AS B18
    ON B17.customer_unique_id = B18.customer_unique_id;

-- 3. Business question: How many January-August 2018 buyers have ANY earlier
-- recorded order before 2018, including available records outside Jan-Aug 2017?
-- Validated result: 687 of 52743 active buyers in Jan-Aug 2018 (1.30%).
-- The denominator is the 2018 buyer total from query 1 / the initial buyer count.
-- Limit: 687 is an observed buyer count, NOT a standard retention rate.
-- The 1.30% share uses 2018 active buyers, not an earlier cohort eligible to return.
-- No earlier recorded order does NOT mean a new customer: dataset history is
-- limited and does not capture all earlier or external purchasing activity.
-- These observations establish neither causes of growth nor measured loyalty.
;WITH buyers_before_2018 AS (
    SELECT DISTINCT C.customer_unique_id
    FROM customers AS C
    INNER JOIN orders AS O ON C.customer_id = O.customer_id
    WHERE O.order_purchase_timestamp < '2018-01-01'
),
buyers_2018 AS (
    SELECT DISTINCT C.customer_unique_id
    FROM customers AS C
    INNER JOIN orders AS O ON C.customer_id = O.customer_id
    WHERE YEAR(O.order_purchase_timestamp) = 2018
      AND MONTH(O.order_purchase_timestamp) BETWEEN 1 AND 8
)
SELECT COUNT(*) AS buyers_with_recorded_orders_before_2018
FROM buyers_before_2018 AS B
INNER JOIN buyers_2018 AS B18
    ON B.customer_unique_id = B18.customer_unique_id;
