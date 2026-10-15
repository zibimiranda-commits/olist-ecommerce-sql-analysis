# Olist E-commerce SQL Analysis

**How did sales performance change between January–August 2017 and January–August 2018, and what factors are associated with that change?**

I use SQL Server to investigate this question with the Brazilian Olist e-commerce dataset. My approach is to start with overall performance, test possible explanations, and check data quality before developing business recommendations.

## Key Results

| Indicator | Jan–Aug 2017 | Jan–Aug 2018 |
| --- | ---: | ---: |
| Item sales (R$) | 3,113,000.32 | 7,385,905.80 |
| Orders | 22,968 | 53,991 |
| Unique buyers | 22,320 | 52,743 |
| Sold product references | 9,859 | 20,495 |
| Active sellers | 1,227 | 2,383 |
| Seller states | 19 | 21 |
| Distinct non-null product categories sold | 70 | 72 |

Item sales increased by **137.3%**, alongside a **135.1%** increase in orders. These figures describe changes between the two periods; they do not establish why the business grew.

The state-level analysis found that:

- Sellers recorded in SP accounted for about **65% of item sales in each period** and **65.12% of the overall sales increase**.
- MA, PA, and PI appeared among active seller states in 2018 and contributed **R$ 39,168.95**, about **0.92% of the overall increase**. AM was present in 2017 and absent in 2018, giving a net increase of two states.

These results were obtained during the analysis. **The repository does not yet contain all supporting queries and result exports.** Completing that archive is the next priority. Geographic allocations remain provisional while seller-location anomalies are investigated.

## Repository Guide

| File | Purpose |
| --- | --- |
| [Database setup](sql/01_database_setup.sql) | Creates the database and nine tables; CSV import is a separate step |
| [Monthly order volume](01_monthly_order_volume.sql) | Counts orders by purchase year and month |
| [Analysis log](ANALYSIS_LOG.md) | Records the investigation sequence, detailed findings, and checks still open |

The two existing SQL scripts retain their original paths so previously shared links continue to work. Their numeric prefixes do not define a repository-wide execution sequence. Comparison, category, seller-state, and geographic-check scripts and their exports are still to be archived; links will be added when those files are available.

## Scope and Metric Definitions

The comparison uses purchase timestamps in `[2017-01-01, 2017-09-01)` and `[2018-01-01, 2018-09-01)`. Monthly exploration showed limited records in 2016 and very few orders after August 2018, so I selected the same eight calendar months in both years. This avoids treating sparse end-of-dataset records as comparable full months; it does not establish the cause of the low counts.

- **Item sales:** `SUM(order_items.price)` in Brazilian reais, excluding freight. This is not Olist's accounting revenue, profit, or total payments.
- **Orders:** distinct `order_id` values in the purchase period.
- **Unique buyers:** distinct `customers.customer_unique_id` values linked to those orders.
- **Sold product references:** distinct `product_id` values in order items, not units or categories.
- **Active sellers:** distinct sellers with at least one order item in the period. An increase in active sellers does not measure recruitment.
- **Seller geography:** the recorded location of the seller, not the buyer or delivery destination. SP refers to the state of São Paulo.

No order-status filter is applied. Cancelled or undelivered orders may be included, and orders without items can contribute to order and buyer counts without contributing item sales. The monthly script counts order rows with non-null purchase timestamps; months without matching rows are not displayed.

## Data Quality and Current Progress

After examining categories, products, buyers, sellers, and state-level sales, I investigated cities within SP. Spelling variants and possible city/state inconsistencies led to city-name cleaning previews and a postal-prefix consistency check.

The check covered all **3,095 sellers**, rather than only sellers active in the comparison periods:

| Geographic status | Sellers |
| --- | ---: |
| CONSISTENT | 3,053 |
| INCONSISTENT | 35 |
| NOT_FOUND | 7 |

The rule compares each seller's state with the most frequent state associated with its ZIP prefix in `geolocation`. It is an internal consistency check, not independent address verification. The **35 mismatches and 7 cases without a reference remain unresolved; no geographic corrections have been applied**. Their impact on geographic sales allocations has not yet been measured.

My next steps are to:

1. Recover or reconstruct the analysis queries, rerun them in SQL Server, reconcile the totals, and save the result exports.
2. Resolve geographic anomalies and recalculate affected measures.
3. Verify the category subtotal and SP product/city comparisons documented in the analysis log.
4. Compare monthly sales and orders to investigate how growth varies within the eight-month windows.
5. Develop business recommendations once the findings are supported by these checks.

## Dataset and Tools

The database contains nine tables: `customers`, `orders`, `order_items`, `order_payments`, `order_reviews`, `products`, `sellers`, `geolocation`, and `product_category_name_translation`.

Tools: Microsoft SQL Server, SQL Server Management Studio (SSMS), SQL, and GitHub. The work covers relational joins, aggregation, conditional comparisons, CTEs, and business interpretation.

## Data Source and License

Source: [Brazilian E-Commerce Public Dataset by Olist](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce), published by Olist on Kaggle under [CC BY-NC-SA 4.0](https://creativecommons.org/licenses/by-nc-sa/4.0/).

The result tables in this documentation are derived summaries of that dataset. These summaries, and any dataset-derived result exports added to this repository, are shared under CC BY-NC-SA 4.0 with attribution to Olist. This notice concerns dataset-derived material and does not assign a license to the SQL code.

Independent educational portfolio project. Not affiliated with or endorsed by Olist.
