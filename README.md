# Olist E-commerce SQL Analysis

**How did sales performance change between January–August 2017 and January–August 2018, and what factors are associated with that change?**

## About This Project

This is an independent portfolio project built with SQL Server and the public Brazilian Olist e-commerce dataset. I treat it like a business investigation: I start from one question, test possible explanations one at a time, check the quality of the data behind each result, and only then draw conclusions. Every result is descriptive. The analysis shows what changed and what is associated with the change; it does not claim to prove why.

The work is published as a LinkedIn series, one episode at a time. This repository holds the SQL scripts, the verified results and the notes behind each episode, so that every number in a post can be traced back to a query.

## The Data

Olist is a Brazilian marketplace connecting small sellers to buyers. The public dataset covers about 100,000 orders placed between 2016 and 2018 and is organised in nine related tables:

| Table | What it contains | Links to |
| --- | --- | --- |
| `orders` | One row per order: purchase date, status, delivery dates | `customers` through `customer_id` |
| `order_items` | One row per item in an order: product, seller, price, freight | `orders`, `products`, `sellers` |
| `customers` | One row per customer_id (one per order), with the buyer's unique ID, city, state and ZIP prefix | `orders` |
| `sellers` | One row per seller, with city, state and ZIP prefix | `order_items` |
| `products` | Product category and physical attributes | `order_items` |
| `product_category_name_translation` | Portuguese to English category names | `products` |
| `order_payments` | Payment type and value per order | `orders` |
| `order_reviews` | Review scores and comments per order | `orders` |
| `geolocation` | Latitude, longitude, city and state for each ZIP prefix | `customers`, `sellers` through the ZIP prefix |

The comparison uses the same eight calendar months in both years (January–August), because 2016 holds few records and very few orders appear after August 2018. The full definitions of each measure are in [Scope and Metric Definitions](#scope-and-metric-definitions).

## How the Project Is Organised

| Chapter | Question | Status |
| --- | --- | --- |
| **Chapter 1: What changed?** (Episodes 1–10) | How big was the growth, and was it driven by more buyers, more categories, new products or more sellers? Did buyers come back? | Done |
| **Chapter 2: Where did growth happen?** | Clean the city and state data, measure the weight of São Paulo on the seller and buyer side, see what distinguishes it (basket, categories, freight) and compare delivery times by location, 2017 vs 2018 | In progress (steps 1–3, seller side) |
| **Chapter 3: Why did buyers not come back?** | Order status, customer reviews and comments, delivery delays and their link to repeat orders | Planned |

Each chapter ends with a conclusion before the next one begins. If a verified result justifies changing this plan, the change is documented in the [analysis log](ANALYSIS_LOG.md).

## How to Read This Repository

- **Start here** for the question, the headline results and the guide to the scripts below.
- **`sql/`** holds one numbered script per step; the number follows the order of the investigation.
- **[VERIFIED_RESULTS_2026_10_15.md](VERIFIED_RESULTS_2026_10_15.md)** records the outputs checked after execution in SSMS.
- **[ANALYSIS_LOG.md](ANALYSIS_LOG.md)** tells the story of the investigation, including the errors and the points still open.

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
| Seller geography check (Chapter 1, Episode 8) | [Sellers by region, ZIP-code consistency check, and city labels](sql/14_seller_geography_check.sql) | Southeast + South: 95.8% / 95.0% of active sellers; 42 of 3,095 sellers flagged by the ZIP-code check (1.4%), 0.73% / 0.57% of item sales; 611 distinct city labels, with 7 labels interpreted as São Paulo (705 sellers) and 9 other labels containing "sao paulo" or "sp" that appear to refer to different places |
| Buyer repeat check (Chapter 1, Episode 9) | [Single-order buyers, everyday-use categories, and a Jan-Mar 2017 follow-up](sql/15_buyer_repeat_categories.sql) | 97.4% / 97.8% of buyers placed a single order; within the same everyday-use group, 1.94% -> 1.09% ordered twice or more (other categories 2.54% -> 2.08%); 5.07% of 5,152 buyers first recorded in Jan-Mar 2017 ordered again |
| Geography audit (Chapter 2, Step 1) | [City-label audit and ZIP-reference comparison](sql/16_chapter2_geography_audit.sql) and [seller city mapping table](sql/17_seller_city_map.sql) | 611 seller city labels (636 city+state pairs) and 4,119 customer labels (4,310 pairs); of 103 sellers whose label is absent from the ZIP reference, 55 had a text error in the city, 32 a registered state that differs from the ZIP state and 14 an unusable label; mapping table: 56 corrected labels (66 sellers), 15 unresolved (18), 2 kept; seller labels 611 -> 548 |
| Robustness checks and seller geography (Chapter 2, Steps 2-3) | [State-vs-ZIP scenario, order-status control, Sao Paulo city vs state, cities by contribution](sql/18_chapter2_checks_and_seller_geography.sql) | SP share of item sales 64.77% / 64.97% (registered state) vs 64.22% / 64.57% (ZIP-based state); delivered orders 95.8% / 97.8% of orders, item sales +141.1% (delivered) vs +137.3% (all statuses); city of Sao Paulo 20.6% / 20.2% of item sales (state of SP about 65%); top 15 cities = 54.1% of the increase |
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

Active sellers (at least one recorded order item in the window) rose from **1,227 to 2,383 (+94.2%)**. Item sales per seller averaged **R$ 2,537.08** then **R$ 3,099.41**, but median item sales per seller were **R$ 607.10** then **R$ 782.24**, about a quarter of the average. In 2018, **55.5%** of sellers sold under R$ 1,000 (6.1% of item sales), while the **63 sellers (2.6%)** at R$ 20,000 or more accounted for **37.2%** of item sales (25 sellers and 29.8% in 2017).

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

The sellers table holds **611 distinct city labels**, still 611 after LOWER and TRIM; this does not prove that case is clean, because SQL Server's default comparison ignores case, but it shows that this basic normalisation does not reduce the count. **Seven labels** are interpreted as São Paulo (705 sellers: "sao paulo" 694, "sp" 4, "sao paulo - sp" 3, and four labels with one seller each), and **nine other labels** containing "sao paulo" or "sp" appear to refer to different places. Reading "sp" as the city of São Paulo is an interpretation. City counts cover all 3,095 sellers and are raw labels, not validated cities. Queries 1 to 3 were executed in SSMS by the analyst.

### Chapter 1 | Episode 9: Did Buyers Come Back?

The [dedicated script](sql/15_buyer_repeat_categories.sql) counts buyers (customer_unique_id) with a single order, compares everyday-use categories with the other categories, and follows buyers first recorded in January-March 2017. Visuals: [overview](images/episode-9/episode-9-cover.png), [query 1](images/episode-9/episode-9-query-1.png), [query 2](images/episode-9/episode-9-query-2.png), [query 3](images/episode-9/episode-9-query-3.png).

Of **22,320** buyers in January-August 2017, **21,733 (97.4%)** placed a single order; of **52,743** in 2018, **51,586 (97.8%)**. Within the same category group, buyers with two or more orders were **1.94% (69 of 3,563)** then **1.09% (111 of 10,143)** for everyday-use categories, and **2.54%** then **2.08%** for the other categories. The everyday-use group made **16.1%** of 2017 item sales and **18.7%** of 2018 (R$ 499,901.04 and R$ 1,383,133.74). Following the **5,152** buyers whose first recorded order was in January-March 2017 over the whole dataset, **261 (5.07%)** ordered again, so about 95% still had a single recorded order.

The everyday-use grouping is an analyst choice, not an Olist classification, and "within the same group" does not count a buyer who orders in two different groups. The cohort rate and the window rates cover different buyers and periods: compare orders of magnitude, not decimals. Queries 1 to 3 were executed in SSMS by the analyst.

### Chapter 2 | Steps 1-3: Cleaning the Geography and Sao Paulo (in progress)

Scripts: [geography audit](sql/16_chapter2_geography_audit.sql), [seller city mapping table](sql/17_seller_city_map.sql), [checks and seller geography](sql/18_chapter2_checks_and_seller_geography.sql). All results were executed in SSMS by the analyst on 20 October 2026 and tie to the validated totals.

**Step 1, city labels.** Sellers hold 611 raw city labels and 636 city+state pairs; customers hold 4,119 labels and 4,310 pairs. No customer label correction was found necessary (letter-only typos would only show up as a mismatch with the ZIP reference, and none was obvious among the 60 unmatched labels): the 163 names that appear under several states are homonyms (the 191 extra pairs are fully explained), and 76 of 99,441 rows (0.08%) carry a locality absent from the ZIP reference. Among sellers, 103 of 3,095 (3.3%) carry a label absent from the reference: 55 have a text error in the city (typo, state or country added, double space, corrupted encoding, hyphen, abbreviation), 32 have a valid city but a registered state that differs from the ZIP state (30 registered in SP), 14 are not usable city names or are ambiguous, and 2 reflect quirks of the reference table. A follow-up check added three corrections and one unresolved label, and left 26 sellers whose valid city label points, by ZIP, to another municipality as registered.

The corrections live in a separate mapping table (`dbo.seller_city_map`); the raw `sellers` table is not modified. It holds 56 corrected labels (66 sellers), 15 unresolved labels (18 sellers) and 2 labels kept as they are; every correction agrees with the ZIP reference city. Seller city labels fall from 611 to 548 and city+state pairs from 636 to 572, with unresolved labels excluded from the "after" count. Abbreviations such as `sbc` are interpretations supported by the ZIP prefix, and the ZIP reference is an internal consistency rule, not address verification.

**Step 2, robustness.** Taking the state from the ZIP prefix instead of the registered state lowers the SP share of item sales by 0.55 point in 2017 (64.77% to 64.22%) and 0.40 point in 2018 (64.97% to 64.57%); its share of the increase moves from 65.12% to 64.82%. The 33 SP-registered sellers whose ZIP points elsewhere all move out of SP (PR 10, SC 7, MG 6, RJ 4, RS 3, DF 1, BA 1, ES 1), and none moves in. The ZIP-based state is a scenario, not a correction. Delivered orders are 95.8% (2017) and 97.8% (2018) of orders and 96.2% and 97.7% of item sales; item sales rose 141.1% over delivered orders only and 137.3% over all statuses, so the increase does not depend on the missing status filter. Orders without items and canceled orders are still present in the Chapter 1 definition, and the reason for 330 orders of 2017 still showing "shipped" is unknown.

**Step 3, Sao Paulo (seller side).** The city of Sao Paulo accounts for 289 of 1,227 active sellers (23.6%) and 20.6% of item sales in 2017, and 522 of 2,383 (21.9%) and 20.2% in 2018; the other cities of the state of SP account for 35.0% then 37.2% of sellers and 44.1% then 44.4% of item sales. Of the R$ 4,272,905.48 increase, the city contributed 19.85% and the other SP cities 44.69%; the SP total remains 65.12%. The top 15 cities contribute 54.1% of the increase, ten of them in SP. A city can rest on very few sellers (Guariba: one active seller in each window, 2.64% of the increase), so these rankings describe where sales were recorded, not why.

Still to come in Chapter 2: buyer-side geography, medians per city, what distinguishes Sao Paulo (basket, categories, freight) and delivery times crossed with seller and buyer location. No causal explanation is drawn from these results.

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
- **Seller geography:** the recorded location of the seller, not the buyer or delivery destination. SP refers to the state of São Paulo.

No order-status filter is applied. Cancelled or undelivered orders may be included, and orders without items can contribute to order and buyer counts without contributing item sales. Chapter 2 (Step 2) checked this choice: delivered orders are 95.8% (2017) and 97.8% (2018) of orders, and item sales rose 141.1% over delivered orders only versus 137.3% over all statuses. The monthly script counts order rows with non-null purchase timestamps; months without matching rows are not displayed.

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

Chapter 2 restarted the seller city cleaning from the raw labels (20 October 2026) and replaces those provisional previews: corrections are held in a separate mapping table, the raw tables are unchanged, registered states are kept as recorded and the ZIP-based state is used only as a scenario (see Chapter 2, Steps 1-3 above). Buyer-side geography has not been audited against the ZIP prefix yet.

My next steps are to:

1. Rerun the remaining monthly, detailed category/product, SP, and geographic queries and save their results.
2. Resolve geographic anomalies and recalculate affected measures (seller side done in Chapter 2, Steps 1-3; buyer side still to do).
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
