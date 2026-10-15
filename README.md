# Olist E-commerce SQL Analysis

**How did sales performance change between Januaryâ€“August 2017 and Januaryâ€“August 2018, and what factors are associated with that change?**

I use SQL Server to investigate this question with the Brazilian Olist e-commerce dataset. My approach is to start with overall performance, test possible explanations, and check data quality before developing business recommendations.

## Key Results

| Indicator | Janâ€“Aug 2017 | Janâ€“Aug 2018 |
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

The period totals, category counts and category appearance/disappearance checks, unique buyers, product-reference counts, active sellers, and state tables were **rerun in SSMS on 15 October 2026** and matched the recorded results. See the [queries executed](sql/08_verified_queries_2026_10_15.sql) and [saved result transcriptions](VERIFIED_RESULTS_2026_10_15.md). The SP city-label count remains provisional, and geographic allocations still depend on unresolved location anomalies.

## SQL Queries and Repository Guide

Click a script or output to open it. The verification script records the query logic executed in SSMS; outputs were copied by the analyst into the project conversation and transcribed into the linked results file. This does not mean that every query in every archived script was rerun.

| Step | Script | Output / verification status |
| --- | --- | --- |
| Database setup | [Create database and nine tables](sql/01_database_setup.sql) | Existing setup; CSV import separate; do not rerun on an existing database |
| Monthly exploration | [Monthly order volume](01_monthly_order_volume.sql) | Historical output in the archive; not rerun in this verification |
| Period comparison | [Item sales and orders](sql/02_sales_and_orders.sql) | [Verified 15 October 2026](VERIFIED_RESULTS_2026_10_15.md#2-period-comparison) |
| Categories | [Counts and category sales](sql/03_categories.sql) | [Counts, appearances and disappearance verified](VERIFIED_RESULTS_2026_10_15.md#3-appearing-and-disappearing-categories); full translated sales table not rerun |
| Buyers and references | [Buyers and product references](sql/04_buyers_and_products.sql) | [Counts verified](VERIFIED_RESULTS_2026_10_15.md#2-period-comparison); detailed product-sales table not rerun |
| Sellers and states | [Sellers and sales by state](sql/05_sellers_and_states.sql) | [Totals and both state tables verified](VERIFIED_RESULTS_2026_10_15.md#4-sellers-and-item-sales-by-state) |
| SP investigation | [SP products and city labels](sql/06_sp_products_and_cities.sql) | [City-label count rerun: 151 / 228, provisional](VERIFIED_RESULTS_2026_10_15.md#5-sp-city-labels--provisional); SP product counts and city lists still pending |
| Geographic quality | [Seller consistency check](sql/07_seller_geographic_check.sql) | Historical 3,095-row output recovered; classification not rerun in this sequence |
| Verification session | [All queries executed on 15 October](sql/08_verified_queries_2026_10_15.sql) | [Results and scope of verification](VERIFIED_RESULTS_2026_10_15.md) |

- [Analysis log](ANALYSIS_LOG.md): investigation sequence, findings, and unresolved questions.
- [Historical recovery archive](requetes-et-resultats-olist.zip): prior queries, outputs, and recovery provenance. It is a historical snapshot and is superseded by the dated verification results where indicated.

The two original scripts retain their existing paths to preserve shared links. Their prefixes do not define a repository-wide execution sequence. The archive remains unchanged; new checks are recorded in dated files rather than overwriting historical results.

## Scope and Metric Definitions

The comparison uses purchase timestamps in `[2017-01-01, 2017-09-01)` and `[2018-01-01, 2018-09-01)`. Monthly exploration showed limited records in 2016 and very few orders after August 2018, so I selected the same eight calendar months in both years. This avoids treating sparse end-of-dataset records as comparable full months; it does not establish the cause of the low counts.

- **Item sales:** `SUM(order_items.price)` in Brazilian reais, excluding freight. This is not Olist's accounting revenue, profit, or total payments.
- **Orders:** distinct `order_id` values in the purchase period.
- **Unique buyers:** distinct `customers.customer_unique_id` values linked to those orders.
- **Sold product references:** distinct `product_id` values in order items, not units or categories.
- **Active sellers:** distinct sellers with at least one order item in the period. An increase in active sellers does not measure recruitment.
- **Seller geography:** the recorded location of the seller, not the buyer or delivery destination. SP refers to the state of SÃ£o Paulo.

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

The latest SP city query returned **151 labels in 2017 and 228 in 2018**. These are provisional raw labels, not validated municipality counts. The older 258 figure is historical; its difference from 228 has not been explained. Cleaning is ongoing.

My next steps are to:

1. Rerun the remaining monthly, detailed category/product, SP, and geographic queries and save their results.
2. Resolve geographic anomalies and recalculate affected measures.
3. Complete SP product/city comparisons; the R$ 6,164.76 appearing-category subtotal and disappearing category were confirmed in the verification session.
4. Compare monthly sales and orders to investigate how growth varies within the eight-month windows.
5. Develop business recommendations once the findings are supported by these checks.

## Dataset and Tools

The database contains nine tables: `customers`, `orders`, `order_items`, `order_payments`, `order_reviews`, `products`, `sellers`, `geolocation`, and `product_category_name_translation`.

Tools: Microsoft SQL Server, SQL Server Management Studio (SSMS), SQL, and GitHub. The work covers relational joins, aggregation, conditional comparisons, CTEs, and business interpretation.

## Data Source and License

Source: [Brazilian E-Commerce Public Dataset by Olist](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce), published by Olist on Kaggle under [CC BY-NC-SA 4.0](https://creativecommons.org/licenses/by-nc-sa/4.0/).

The result tables in this documentation are derived summaries of that dataset. These summaries, and any dataset-derived result exports added to this repository, are shared under CC BY-NC-SA 4.0 with attribution to Olist. This notice concerns dataset-derived material; it is separate from the code license below.

Independent educational portfolio project. Not affiliated with or endorsed by Olist.

## Code License

The original SQL scripts in this repository are licensed under the [MIT License](LICENSE), copyright (c) 2026 zibimiranda-commits.

The MIT License does not apply to the Olist source dataset, dataset-derived result tables or exports, or third-party material. Those data-derived materials retain CC BY-NC-SA 4.0 as described above, including the historical result outputs in the recovery archive.
