# Olist E-commerce SQL Analysis

## Project Overview

This project analyzes the Brazilian Olist e-commerce dataset using SQL Server.

The goal is not only to execute SQL queries, but to use data to identify business problems, investigate their causes, and provide actionable recommendations.

## Business Context

Olist has data covering orders, products, customers, sellers, payments, deliveries, and customer reviews.

Before assuming what the main business problem is, the first objective of this project is to understand the company's sales performance and identify potential areas of underperformance.

## Initial Business Question

**How did Olist's sales performance change between January–August 2017 and January–August 2018, and what factors are associated with this evolution?**

### Analysis Period

An initial exploration of the order data showed that 2016 contains only a limited number of orders. The comparison uses the same eight-month period in each year: **January to August 2017 vs January to August 2018**.

Periods are defined using `orders.order_purchase_timestamp`: `[2017-01-01, 2017-09-01)` and `[2018-01-01, 2018-09-01)`. September and October are excluded from this comparison.

The investigation progressed from period selection and overall sales and order comparisons to product categories, product references, buyers, active sellers, seller states, and cities within SP. Geographic data-quality issues emerged during the city-level investigation.

Further investigations may include product categories, sellers, customers, geographic patterns, delivery performance, and customer satisfaction, depending on the findings.

### Monthly Order Volume Exploration

Before selecting the comparison periods, I used SQL Server to calculate monthly order volumes based on purchase timestamps.

The query groups orders by year and month, allowing me to examine the distribution of recorded orders across the dataset.

This exploration highlighted limited records in 2016 and a sharp reduction in recorded orders after August 2018. These observations informed the decision to compare January–August 2017 with January–August 2018.

**SQL script:** [Monthly Order Volume](01_monthly_order_volume.sql)

The query excludes records with missing purchase timestamps and does not filter by order status. Months without matching records do not appear in the query results.

### Metric Definitions

- **Item sales (CA in the analysis):** `SUM(order_items.price)` in Brazilian reais (R$), excluding freight. This measures the value of items sold, not Olist's accounting revenue, profit, or total payments.
- **Orders:** distinct `order_id` values in `orders` during each period.
- **Unique buyers:** distinct `customers.customer_unique_id` values linked to orders during each period, rather than distinct `customer_id` values.
- **Sold product references:** distinct `product_id` values in order items during each period, not units sold or product categories.
- **Active sellers:** distinct sellers with at least one order item during each period.
- **Seller states:** distinct `sellers.seller_state` values for active sellers. These describe seller locations, not buyer locations or delivery coverage.

No order-status filter is applied. Cancelled or undelivered orders may therefore be included. Orders without items can contribute to order and buyer counts without contributing to item sales.

### Results So Far

The following figures were recorded in the prior analysis and reviewed against the available conversation history for this documentation update. Some original outputs are available only as attachments that could not be inspected in this review; these limitations are identified below. No queries were re-executed against SQL Server. Percentages reported below are arithmetic calculations from the recorded amounts, not new database results.

| Indicator | Jan–Aug 2017 | Jan–Aug 2018 |
| --- | ---: | ---: |
| Item sales (R$) | 3,113,000.32 | 7,385,905.80 |
| Orders | 22,968 | 53,991 |
| Unique buyers | 22,320 | 52,743 |
| Sold product references | 9,859 | 20,495 |
| Active sellers | 1,227 | 2,383 |
| Seller states | 19 | 21 |
| Distinct non-null product categories sold | 70 | 72 |

Item sales increased by **137.3%**. This growth coincided with more orders, unique buyers, sold product references, and active sellers. These comparisons describe associated changes; they do not yet establish the causes of growth.

Three states appeared among active seller locations in the 2018 comparison period: **MA (Maranhão), PA (Pará), and PI (Piauí)**. **AM (Amazonas)** was represented in 2017 but absent among active seller locations in the 2018 period. The net change was therefore **two additional seller states**, from 19 to 21. This does not establish when sellers joined or left Olist.

### Investigation Sequence and Findings

#### 1. Establish comparable periods

The initial exploration checked the available years and months. A January–October comparison was tried first, with an early growth estimate of about 67–68%. That window was superseded after monthly order counts showed uneven coverage: 329 recorded orders in 2016, 6,512 in August 2018, 16 in September 2018, and 4 in October 2018. The retained comparison covers January–August in both years, including all of August. The earlier ten-month estimate is not the final growth result. Low recorded counts alone do not establish a real business decline.

The complete monthly order-count series was also revisited later to document this decision and prepare a chart; documentation order should not be confused with the order of the original investigation.

#### 2. Calculate item sales and compare order volumes

The analysis examined the relationship between orders and their items, including the fact that one order can contain multiple item rows. Item prices were summed by order and then by period. Item sales rose by R$ 4,272,905.48 (+137.3%), while recorded orders increased from 22,968 to 53,991 (+135.1%). This comparison establishes growth relative to 2017, not performance against an unspecified average or target.

#### 3. Investigate product categories and references

The next question was whether a broader assortment accompanied the increase in sales and orders. The analysis listed and counted sold categories, calculated sales by category for each period, and joined the category translation table to display English labels.

There were 70 distinct non-null categories in 2017 and 72 in 2018. This is a net difference, not proof that exactly two categories appeared. A year/category table contains repeated category names across years, and a null-category sales group can produce an additional row.

A recap shared during the prior analysis reports R$ 6,164.76 in 2018 sales from categories absent from the 2017 comparison period: approximately 0.14% of the overall sales increase. The original output behind this subtotal was not independently recoverable in this review, so this remains a recorded result pending reconciliation with the saved query and output. It does not explain most of the increase.

The investigation then moved to individual product references and their sales by year. Distinct sold references increased from 9,859 to 20,495. Detailed product-level results were shared as attachments; their complete contents and conclusions could not be reconstructed from the accessible text.

#### 4. Compare buyers and active sellers

Unique buyers increased from 22,320 to 52,743, using `customer_unique_id`. Active sellers increased from 1,227 to 2,383. These are period activity counts: the difference does not measure newly recruited sellers or distinguish entry, reactivation, and inactivity.

#### 5. Compare seller states and measure their sales

The analysis counted represented seller states, listed active sellers by state and year, and built a side-by-side comparison using conditional aggregation. MA, PA, and PI appeared in 2018 with one active seller each, while AM had one in 2017 and none in 2018.

Item sales were then calculated by seller state for both periods. The three appearing states contributed:

| Seller state | Jan–Aug 2017 item sales (R$) | Jan–Aug 2018 item sales (R$) |
| --- | ---: | ---: |
| MA | 0.00 | 36,408.95 |
| PA | 0.00 | 238.00 |
| PI | 0.00 | 2,522.00 |
| **Total** | **0.00** | **39,168.95** |

This is approximately 0.92% of the overall sales increase, or 0.53% of total 2018 item sales. Their contribution was therefore already investigated and was small relative to overall growth. This concerns seller locations, not customer-market expansion.

#### 6. Identify SP's weight and investigate it further

| SP indicator | Jan–Aug 2017 | Jan–Aug 2018 |
| --- | ---: | ---: |
| Active sellers | 723 | 1,417 |
| Item sales (R$) | 2,016,153.52 | 4,798,484.69 |
| Share of overall item sales | 64.77% | 64.97% |

SP accounted for approximately 65.12% of the overall sales increase. **SP here is the state of São Paulo, not just the city of São Paulo.** These are provisional geographic allocations based on the recorded seller states; their sensitivity to unresolved geographic inconsistencies has not been measured.

The next hypotheses concerned assortment expansion within SP and a larger seller network. A query on distinct product references sold by SP sellers was explored; the conversation describes a doubling, but the exact output was attached as an image and could not be independently recovered here. Neither a product-attractiveness explanation nor a distribution strategy has been established.

#### 7. Compare seller cities within SP and identify data-quality issues

Before continuing the SP product comparison, the investigation counted distinct recorded city names for active SP sellers and compared names present in only one period. The initial raw counts were 151 in 2017 and 258 in 2018. These are unstandardized labels, not validated counts of municipalities or proof of geographic expansion.

The lists exposed spelling variants, abbreviations, encoding problems, and possible city/state inconsistencies. This prompted work on city-name standardization and postal-prefix checks. Later counts of 147 and 209, and a reference to 55 appearing cities, occur during that quality-work stage and cannot be treated as equivalent to the original raw counts without recovering the exact query definitions. No independently recoverable result establishes the sales contribution of those 55 cities. The small contribution demonstrated above concerns MA, PA, and PI, not those city labels.

City-cleaning previews using `CASE` were explored. A transformed query result alone does not prove that source rows were updated. The investigation remains ongoing, and final business recommendations have not been developed.

### Seller Geographic Consistency Check

After the overall period comparison and the comparison of active seller states, a geographic consistency check was performed on the full sellers table, rather than only sellers active in either comparison period.

The check compares each seller's recorded state with a reference state derived from the seller's ZIP code prefix in `geolocation`. The reference is the most frequent state for that prefix; the query shared during the analysis uses state code order to break frequency ties. This is a consistency rule, not an independently verified address reference.

| Geographic status | Sellers |
| --- | ---: |
| CONSISTENT | 3,053 |
| INCONSISTENT | 35 |
| NOT_FOUND | 7 |
| **Total** | **3,095** |

`CONSISTENT` means the recorded seller state matches the derived reference state. `INCONSISTENT` means the states differ. `NOT_FOUND` means no non-null reference state was available through the ZIP-prefix lookup; it does not establish that the seller's address is invalid.

These counts were verified in the prior SQL Server work and supplied for this documentation update. They were not re-executed against SQL Server during this repository review. The 35 mismatches and 7 cases without a reference remain unresolved: **no geographic corrections have been applied**. A mismatch alone does not identify which source is wrong. The impact on the previously reported seller-state comparison has not yet been assessed.

### Repository Coverage and Reproducibility

The repository currently contains two SQL scripts:

- [Database setup](sql/01_database_setup.sql): creates the database and nine tables. Although its header mentions data import, the script contains no CSV import commands.
- [Monthly order volume](01_monthly_order_volume.sql): counts order rows by purchase year and month, excluding null purchase timestamps and applying no order-status filter.

The SQL scripts for the 2017/2018 metric comparison, category and product investigations, buyer and seller comparisons, state-level sales analysis, SP city comparisons, and the seller geographic consistency check are not yet included. Their documented results must not be mistaken for queries reproducible from the current repository alone. The original saved queries and result exports should be added in separate files when recovered, without overwriting existing scripts.

The README records data import and validation as completed prior work. Import instructions, validation queries, and saved result outputs are not currently included in the repository. The monthly query itself does not preserve its execution results.

## Dataset

The database contains 9 main tables:

- customers
- orders
- order_items
- order_payments
- order_reviews
- products
- sellers
- geolocation
- product_category_name_translation

## Tools

- Microsoft SQL Server
- SQL Server Management Studio (SSMS)
- SQL
- GitHub

## Project Progress

### Completed in the Prior Analysis

- Database and nine-table creation, CSV import, and initial validation
- Exploration of table structure, granularity, joins, and date coverage
- Revision of the initial ten-month comparison to January–August
- Comparison of item sales, orders, sold categories, product references, buyers, and active sellers
- Category-level sales exploration, including a recorded subtotal for categories appearing in 2018
- Active seller counts by state and identification of appearing/disappearing states
- Calculation of sales by seller state and the limited contribution of MA, PA, and PI
- Identification of SP's sales concentration and investigation of its sellers, products, and raw city labels
- Detection of city-label and geographic inconsistencies; exploration of cleaning previews
- Seller geographic consistency check: 3,095 sellers classified, with 35 mismatches and 7 cases without a reference remaining unresolved

### In Progress

- City-name standardization and investigation of geographic inconsistencies
- Assessment of how data quality affects geographic interpretation
- Investigation of factors associated with sales growth; causal explanations remain open

### Next Steps

- Recover and archive original queries and outputs in separate files without overwriting existing scripts
- Reconcile category subtotals and SP product/city results with their original query definitions
- Investigate geographic anomalies before deciding on corrections, then recalculate affected measures
- Quantify sales associated with appearing SP cities after validating the labels and geographic assignments
- Distinguish seller entry/exit from changes in activity and compare product assortment, quantities, and prices
- Deepen monthly and segment-level analysis; investigate delivery and satisfaction if findings warrant it
- Develop business recommendations supported by verified findings

## Skills Demonstrated

- SQL Server
- Data preparation
- Relational databases
- Business problem definition
- Exploratory data analysis
- SQL querying
- Business-oriented data analysis
