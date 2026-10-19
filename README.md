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

The period totals, category counts and category appearance/disappearance checks, unique buyers, product-reference counts, active sellers, and state tables were **rerun in SSMS on 15 October 2026** and matched the recorded results. See the [separate sales and order queries](sql/02_sales_and_orders.sql) and [saved result transcriptions](VERIFIED_RESULTS_2026_10_15.md). The SP city-label count remains provisional, and geographic allocations still depend on unresolved location anomalies.

## SQL Queries and Repository Guide

The period-comparison file contains the three separate queries supplied by the project author: order count, item sales, and item sales per recorded order. Their logic is preserved as supplied, without introducing a combined `WITH` query. Other scripts will be reviewed step by step as the project progresses.

| Step | Queries used | Results |
| --- | --- | --- |
| Database setup | [Create database and nine tables](sql/01_database_setup.sql) | Existing setup; import CSVs separately; do not rerun on an existing database |
| Monthly exploration | [Monthly order volume](01_monthly_order_volume.sql) | Historical output in the recovery archive |
| Period comparison | [Three queries: orders, item sales, and value per order](sql/02_sales_and_orders.sql) | [Verified totals and per-order calculation](VERIFIED_RESULTS_2026_10_15.md#2-period-comparison) |
| Category counts | [Distinct categories by year](sql/03_categories.sql) | [70 and 72; category checks documented separately](VERIFIED_RESULTS_2026_10_15.md#3-appearing-and-disappearing-categories) |
| Buyers and references | [Separate buyer and product-reference counts](sql/04_buyers_and_products.sql) | [Verified counts](VERIFIED_RESULTS_2026_10_15.md#2-period-comparison) |
| Buyer growth and repeat purchasing (Chapter 1, Episode 3) | [Three queries: order frequency, 2017/2018 overlap, and pre-2018 buyer history](sql/09_buyer_repeat_purchasing.sql) | Single-order buyers: 97.37% / 97.81%; matched-window overlap: 341; prior recorded buyers: 687 of 52,743 (1.30%) |
| Category contribution (Chapter 1, Episode 4) | [Category sales, contribution to the increase, and appearing categories](sql/10_category_contribution.sql) | Top 10 categories: 67.5% of the increase; 59 of 73 categories grew; categories absent in 2017: 0.14% ([details](VERIFIED_RESULTS_2026_10_15.md#3-appearing-and-disappearing-categories)) |
| Product turnover (Chapter 1, Episode 5) | [Product sales by window, product groups, and earlier-sale test](sql/11_product_turnover.sql) | 2,436 products sold in both windows; 15,500 of 20,495 products sold in 2018 (75.6%) had no recorded sale before 2018, generating R$ 4,490,754.07 (60.8% of 2018 item sales) |
| Seller analysis (Chapter 1, Episode 6) | [Sales by seller, average vs median, and sales bands](sql/12_seller_analysis.sql) | Active sellers rose from 1,227 to 2,383; median item sales per seller R$ 607.10 → R$ 782.24 (average R$ 2,537.08 → R$ 3,099.41); 63 sellers (2.6%) at R$ 20,000+ accounted for 37.2% of 2018 item sales |
| Seller continuity (Chapter 1, Episode 7) | [Seller groups, earlier history, and continuation by sales band](sql/13_seller_continuity.sql) | 686 of 2,383 sellers active in 2018 (28.8%) were also active in January-August 2017; 1,284 (53.9%) had no recorded sale before 2018 and made 30.0% of 2018 item sales; 92.0% of 2017's top-band sellers (23 of 25) were active again in 2018 vs 43.1% of the under-R$ 1,000 band |
| Seller geography check (Chapter 1, Episode 8) | [Sellers by region, ZIP-code consistency check, and city labels](sql/14_seller_geography_check.sql) | Southeast + South: 95.8% / 95.0% of active sellers; 42 of 3,095 sellers flagged by the ZIP-code check (1.4%), 0.73% / 0.57% of item sales; 611 distinct city labels, with São Paulo written 7 ways (705 sellers) and 9 other cities hiding behind "sao paulo" or "sp" |
| Sellers and states | [Seller counts, state comparison and state sales](sql/05_sellers_and_states.sql) | [Verified totals and state tables](VERIFIED_RESULTS_2026_10_15.md#4-sellers-and-item-sales-by-state) |
| SP city labels | [Distinct recorded city labels](sql/06_sp_products_and_cities.sql) | [151 / 228, provisional while cleaning continues](VERIFIED_RESULTS_2026_10_15.md#5-sp-city-labels--provisional) |

### Episode 2: The Three Queries

Open [02_sales_and_orders.sql](sql/02_sales_and_orders.sql) to see the three queries in order:

1. `COUNT(DISTINCT order_id)` directly from `orders` counts recorded orders.
2. An `INNER JOIN` from `orders` to `order_items` and `SUM(I.price)` calculates item sales.
3. A `LEFT JOIN` retains orders without item rows, while `COUNT(DISTINCT O.order_id)` prevents multi-item orders from being counted more than once. `ROUND(SUM(I.price) / COUNT(DISTINCT O.order_id), 2)` calculates item sales per recorded order, rounded to two decimal places.

All three queries use purchase timestamps for January–August in 2017 and 2018, with no order-status filter. The third query is the author's supplied calculation of the same per-order ratio; its specific SQL output has not been newly supplied in this update. The dated verification record retains the earlier SSMS checks and the ratio calculated from their confirmed totals.

### Chapter 1 | Episode 3: Buyer Growth vs. Repeat Purchasing

This follow-up extends the [initial buyer counts](sql/04_buyers_and_products.sql). The [three dedicated queries](sql/09_buyer_repeat_purchasing.sql) examine order frequency within each January-August window, buyers observed in both windows, and the broader recorded history before 2018.

Active buyers increased from **22,320 to 52,743 (+136.3%)**. In 2017, **21,733 / 537 / 50** buyers placed **1 / 2 / 3+** distinct orders within January-August; in 2018, the counts were **51,586 / 1,085 / 72**. Single-order buyers represented **97.37%** and **97.81%**, respectively. **341** buyers appeared in both January-August windows. Expanding the earlier-history search to all available orders before 2018 identifies **687** of the **52,743** January-August 2018 buyers (**1.30%**).

These are results supplied as validated by the analyst, not newly rerun for this repository update. All three queries use purchase timestamps, identify buyers by `customer_unique_id`, and apply no order-status filter. Frequency covers each selected window only. The 1.30% describes the share of 2018 active buyers with earlier recorded orders; it is **not a standard retention rate**. No order recorded before 2018 does **not** establish that someone is a new customer. Limited dataset history and these descriptive comparisons do not establish causes of growth or measured customer loyalty.

### Chapter 1 | Episode 4: Which Categories Contributed Most?

This follow-up extends the [category counts](sql/03_categories.sql). The [dedicated script](sql/10_category_contribution.sql) compares item sales by category in January–August 2017 and 2018 (with the English translation table), ranks categories by their contribution to the increase, and checks categories present in one window only.

Categories sold for the first time in the 2018 window (no sale recorded in January–August 2017) account for only about **0.14%** of the increase. The **top 10 categories contributed 67.5%** of it, and **59 of 73** categories sold more in 2018. Growth was therefore broad and came mostly from existing categories. **Health & beauty** ranked first by contribution, and **Watches & gifts** moved from 6th to 2nd by sales.

Contribution = item sales 2018 − item sales 2017. It combines category size and growth speed, and it does not establish causes. Item sales exclude freight, apply no order-status filter, and are not Olist's official revenue. Results are supplied as validated by the analyst, not newly rerun for this repository update.

### Chapter 1 | Episode 5: Were the Products the Same?

This follow-up extends the [category contribution analysis](sql/10_category_contribution.sql) at product level. The [dedicated script](sql/11_product_turnover.sql) compares item sales per product in January-August 2017 and 2018, groups products by whether they sold in one or both windows, and tests whether the products sold in 2018 had any recorded sale before 1 January 2018.

Distinct product IDs sold increased from **9,859 to 20,495 (+107.9%)**; counts refer to distinct `product_id` values, not units sold. Across both windows, **27,918** products sold at least once: **2,436** in both windows, **18,059** in January-August 2018 only, and **7,423** in January-August 2017 only. Of the 20,495 products sold in 2018, **15,500 (75.6%)** had no recorded sale before 2018 and generated **R$ 4,490,754.07 (60.8%)** of 2018 item sales; **4,995** had sold before 2018 (R$ 2,895,151.73).

"No recorded sale" in a window or before 2018 does **not** establish that a product is new or discontinued: the dataset's history is limited and product identifiers may change. These are descriptive comparisons and do not explain why the product mix changed. Item sales exclude freight, apply no order-status filter, and are not Olist's official revenue. Results are supplied as validated by the analyst, not newly rerun for this repository update.

### Chapter 1 | Episode 6: Who Were the Sellers?

The [dedicated script](sql/12_seller_analysis.sql) builds one row per seller and year for January-August 2017 and 2018, then summarises it: average versus median item sales per seller, and the number of sellers and item sales in four sales bands.

Active sellers (at least one item sold in the window) rose from **1,227 to 2,383 (+94.2%)**. Item sales per seller averaged **R$ 2,537.08** then **R$ 3,099.41**, but median item sales per seller were **R$ 607.10** then **R$ 782.24**, about a quarter of the average. In 2018, **55.5%** of sellers sold under R$ 1,000 (6.1% of item sales), while the **63 sellers (2.6%)** at R$ 20,000 or more accounted for **37.2%** of item sales (25 sellers and 29.8% in 2017).

Visuals: [overview](images/episode-6/episode-6-cover.png) · [query 1: sales by seller](images/episode-6/episode-6-query-1.png) · [query 2: average vs median](images/episode-6/episode-6-query-2.png) · [query 3: sales bands](images/episode-6/episode-6-query-3.png)

The bands (R$ 1,000 / 5,000 / 20,000) are thresholds chosen for this analysis, not an Olist classification. These are descriptive comparisons and do not explain why sellers joined or grew. Item sales exclude freight, apply no order-status filter, and are not Olist's official revenue. Results were executed in SSMS by the analyst and tie to the validated totals.

### Chapter 1 | Episode 7: Were the Sellers the Same?

The [dedicated script](sql/13_seller_continuity.sql) compares which sellers were active in January-August 2017 and January-August 2018, tests whether the sellers active in 2018 had any recorded sale before 1 January 2018, and measures how many 2017 sellers were active again in 2018 by 2017 sales band. Visuals: [overview](images/episode-7/episode-7-cover.png) · [query 1: seller groups](images/episode-7/episode-7-query-1.png) · [query 2: earlier history](images/episode-7/episode-7-query-2.png) · [query 3: active again by band](images/episode-7/episode-7-query-3.png)

Of the **2,383** sellers active in 2018, **686 (28.8%)** were also active in the 2017 window and **1,697** were active in the 2018 window but not in the 2017 window; **541** of the 1,227 sellers active in 2017 had no sale in the 2018 window. The 686 accounted for 82.8% of 2017 item sales and 49.7% of 2018 item sales (R$ 3,672,980.53 of R$ 7,385,905.80). **1,284 (53.9%)** of the 2018 sellers had no recorded sale before 2018 and made **R$ 2,214,796.80 (30.0%)** of 2018 item sales; 1,099 had sold before 2018. Of the 2017 sellers, **43.1%** (323 of 749) of the under-R$ 1,000 band, **70.8%** (228 of 322), **85.5%** (112 of 131) and **92.0%** (23 of 25) of the R$ 20,000-or-more band were active again in 2018.

"No recorded sale before 2018" means no order item before 1 January 2018 in this dataset; it does **not** establish that a seller is new. The sales bands are thresholds chosen for this analysis, and the top band held only 25 sellers in 2017. These are descriptive comparisons and do not explain why sellers stayed or stopped selling. Item sales exclude freight, apply no order-status filter, and are not Olist's official revenue. Queries 1 to 3 were executed in SSMS by the analyst and tie to the validated totals.

### Chapter 1 | Episode 8: Where Were the Sellers?

The [dedicated script](sql/14_seller_geography_check.sql) groups active sellers by registered region, tests each registered state against the state suggested by the seller's ZIP prefix, and inspects the city labels. Visuals: [overview](images/episode-8/episode-8-cover.png) · [query 1: sellers by region](images/episode-8/episode-8-query-1.png) · [query 2: ZIP-code check](images/episode-8/episode-8-query-2.png) · [query 3: city labels](images/episode-8/episode-8-query-3.png)

More than 95% of active sellers were registered in the Southeast (SP, MG, RJ, ES) or the South (PR, SC, RS): **95.8%** of 1,227 sellers in 2017 (909 and 267) and **95.0%** of 2,383 in 2018 (1,752 and 513); all other regions held 51 and 118 sellers. SP alone held 723 of 1,227 sellers (58.9%) and 1,417 of 2,383 (59.5%), about 65% of item sales in both windows.

The ZIP-code check flagged **42 of 3,095 sellers (1.4%)**: 35 INCONSISTENT (33 of them registered in SP) and 7 NOT_FOUND. They made R$ 22,818.61 of 2017 item sales (0.73%) and R$ 42,065.65 of 2018 (0.57%); the three statuses tie to R$ 3,113,000.32 and R$ 7,385,905.80. The states therefore held up to this consistency check. It is an internal rule, not address verification, and no state was corrected.

The sellers table holds **611 distinct city labels**, still 611 after LOWER and TRIM; this does not prove that case is clean, because SQL Server's default comparison ignores case, but it shows that basic normalisation removes nothing. São Paulo is written in **seven ways** (705 sellers: "sao paulo" 694, "sp" 4, "sao paulo - sp" 3, and four labels with one seller each), and **nine other cities** hide behind "sao paulo" or "sp". Reading "sp" as the city of São Paulo is an interpretation. City counts cover all 3,095 sellers and are raw labels, not validated cities. Queries 1 to 3 were executed in SSMS by the analyst.

### Guided Checks and Work to Revisit

The following files preserve assisted checks and recovery history. They are not a claim that the original analysis used these consolidated methods independently:

- [Guided seller geographic check](sql/07_seller_geographic_check.sql): uses CTEs and ranking; the method will be revisited step by step. The 3,095-row historical output is preserved; anomalies remain unresolved.
- [Guided verification-session record](sql/08_verified_queries_2026_10_15.sql): includes the category CTE, window-function total and EXCEPT check executed during verification. Its advanced sections are supporting records, not the main workflow for Episode 2.
- [Dated results](VERIFIED_RESULTS_2026_10_15.md): transcriptions of outputs supplied after SSMS execution, with the scope of each check.
- [Analysis log](ANALYSIS_LOG.md): investigation sequence, findings, and unresolved questions.
- [Historical recovery archive](requetes-et-resultats-olist.zip): recovered outputs and earlier reconstructed drafts. It remains a historical snapshot; use the main scripts above for the current presentation of the analysis.

Existing paths are retained so shared links continue to open. Earlier drafts remain in Git history and the recovery archive. No new combined CTE for sales, orders and per-order value has been published.

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

The rule compares each seller's state with the most frequent state associated with its ZIP prefix in `geolocation`. It is an internal consistency check, not independent address verification. The **35 mismatches and 7 cases without a reference remain unresolved; no geographic corrections have been applied**. Their impact on sales was measured in Episode 8: 0.73% of 2017 and 0.57% of 2018 item sales.

The latest SP city query returned **151 labels in 2017 and 228 in 2018**. These are provisional raw labels, not validated municipality counts. The older 258 figure is historical; its difference from 228 has not been explained. Cleaning is ongoing.

My next steps are to:

1. Rerun the remaining monthly, detailed category/product, SP, and geographic queries and save their results.
2. Resolve geographic anomalies and recalculate affected measures.
3. Complete SP product/city comparisons; the R$ 6,164.76 appearing-category subtotal and disappearing category were confirmed in the verification session.
4. Compare monthly sales and orders to investigate how growth varies within the eight-month windows.
5. Develop business recommendations once the findings are supported by these checks.

## Dataset and Tools

The database contains nine tables: `customers`, `orders`, `order_items`, `order_payments`, `order_reviews`, `products`, `sellers`, `geolocation`, and `product_category_name_translation`.

Tools: Microsoft SQL Server, SQL Server Management Studio (SSMS), SQL, and GitHub. The main analysis uses SELECT, date filters, distinct counts, SUM, GROUP BY, joins and CASE comparisons. CTEs also support the Episode 3 buyer follow-up; CTEs and ranking appear in guided checks that will be revisited separately.

## Data Source and License

Source: [Brazilian E-Commerce Public Dataset by Olist](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce), published by Olist on Kaggle under [CC BY-NC-SA 4.0](https://creativecommons.org/licenses/by-nc-sa/4.0/).

The result tables in this documentation are derived summaries of that dataset. These summaries, and any dataset-derived result exports added to this repository, are shared under CC BY-NC-SA 4.0 with attribution to Olist. This notice concerns dataset-derived material; it is separate from the code license below.

Independent educational portfolio project. Not affiliated with or endorsed by Olist.

## Code License

The original SQL scripts in this repository are licensed under the [MIT License](LICENSE), copyright (c) 2026 zibimiranda-commits.

The MIT License does not apply to the Olist source dataset, dataset-derived result tables or exports, or third-party material. Those data-derived materials retain CC BY-NC-SA 4.0 as described above, including the historical result outputs in the recovery archive.
