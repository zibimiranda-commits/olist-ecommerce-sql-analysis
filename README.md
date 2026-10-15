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

These results were obtained during the analysis. Supporting queries have now been recovered, corrected, or reconstructed from the working record and linked below. **The prepared scripts have not yet been rerun in SQL Server.** Recovered historical outputs are preserved in the downloadable archive; they are not exports from a new database run. Geographic allocations remain provisional while seller-location anomalies are investigated.

## SQL Queries and Repository Guide

Click a query name to open its SQL file. Each script header distinguishes recovered code from corrected or reconstructed code. The analysis scripts use read-only queries; the database setup file creates the database and tables and should not be rerun on an existing database.

| Step | SQL file | Recovery status |
| --- | --- | --- |
| Database setup | [Create the database and nine tables](sql/01_database_setup.sql) | Existing setup script; CSV import is separate |
| Monthly exploration | [Monthly order volume](01_monthly_order_volume.sql) | Existing script, also recovered from the working record |
| Period comparison | [Item sales and orders](sql/02_sales_and_orders.sql) | Order query recovered; sales query reconstructed |
| Product categories | [Category counts, sales, and appearing categories](sql/03_categories.sql) | 2017 count recovered; comparative queries reconstructed |
| Buyers and references | [Unique buyers and product references](sql/04_buyers_and_products.sql) | Buyer syntax corrected; product queries reconstructed |
| Seller geography | [Active sellers and sales by state](sql/05_sellers_and_states.sql) | Counts recovered; conditional sales syntax corrected |
| SP investigation | [SP product references and raw city labels](sql/06_sp_products_and_cities.sql) | City alias corrected; product and city-list queries reconstructed |
| Geographic quality | [Seller geographic consistency check](sql/07_seller_geographic_check.sql) | CTE and summary corrected/reconstructed; no data corrections |

- [Detailed analysis log](ANALYSIS_LOG.md): the investigation sequence, findings, and unresolved questions.
- [Download recovered queries, outputs, and provenance](requetes-et-resultats-olist.zip): includes monthly counts, category sales, seller/state tables, and the original 3,095-row geographic output. The recovery note identifies each source and every reconstruction.

The two existing scripts retain their original paths to preserve previously shared links. Their prefixes do not define a repository-wide execution sequence. The archive's comparison summary is transcribed from a prior recap; the detailed monthly, category, state, and geographic outputs were recovered separately. Fresh execution exports still need to be saved and reconciled.

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

1. Rerun the linked scripts in SQL Server, compare them with the recovered historical outputs, and save fresh result exports.
2. Resolve geographic anomalies and recalculate affected measures.
3. Verify the SP product/city comparisons; the R$ 6,164.76 category subtotal has now been reconciled with the recovered detailed category rows.
4. Compare monthly sales and orders to investigate how growth varies within the eight-month windows.
5. Develop business recommendations once the findings are supported by these checks.

## Dataset and Tools

The database contains nine tables: `customers`, `orders`, `order_items`, `order_payments`, `order_reviews`, `products`, `sellers`, `geolocation`, and `product_category_name_translation`.

Tools: Microsoft SQL Server, SQL Server Management Studio (SSMS), SQL, and GitHub. The work covers relational joins, aggregation, conditional comparisons, CTEs, and business interpretation.

## Data Source and License

Source: [Brazilian E-Commerce Public Dataset by Olist](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce), published by Olist on Kaggle under [CC BY-NC-SA 4.0](https://creativecommons.org/licenses/by-nc-sa/4.0/).

The result tables in this documentation are derived summaries of that dataset. These summaries, and any dataset-derived result exports added to this repository, are shared under CC BY-NC-SA 4.0 with attribution to Olist. This notice concerns dataset-derived material and does not assign a license to the SQL code.

Independent educational portfolio project. Not affiliated with or endorsed by Olist.
