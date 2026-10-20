# Analysis Log

[Back to the project overview](README.md)

I use this log to record the questions I explored, the results obtained, and the checks still needed. Recovered, corrected, and reconstructed queries are now linked from the README. Historical outputs are preserved in the recovery archive. The [dated verification record](VERIFIED_RESULTS_2026_10_15.md) now confirms the rerun period totals, category checks, buyer/product counts, and seller/state tables. Remaining queries are identified separately; SP city findings remain provisional.

## Investigation Sequence and Findings

### 1. Establish comparable periods

[Monthly order-volume query](01_monthly_order_volume.sql)

The initial exploration checked the available years and months. A Januaryâ€“October comparison was tried first, with an early growth estimate of about 67â€“68%. That window was superseded after monthly order counts showed uneven coverage: 329 recorded orders in 2016, 6,512 in August 2018, 16 in September 2018, and 4 in October 2018. The retained comparison covers Januaryâ€“August in both years, including all of August. The earlier ten-month estimate is not the final growth result. Low recorded counts alone do not establish a real business decline.

The complete monthly order-count series was also revisited later to document this decision and prepare a chart; documentation order should not be confused with the order of the original investigation.

### 2. Calculate item sales and compare order volumes

[Sales and orders queries](sql/02_sales_and_orders.sql)

The analysis examined the relationship between orders and their items, including the fact that one order can contain multiple item rows. Item prices were summed by order and then by period. Item sales rose by R$ 4,272,905.48 (+137.3%), while recorded orders increased from 22,968 to 53,991 (+135.1%). This comparison establishes growth relative to 2017, not performance against an unspecified average or target.

### 3. Investigate product categories and references

[Category queries](sql/03_categories.sql)

The next question was whether a broader assortment accompanied the increase in sales and orders. The analysis listed and counted sold categories, calculated sales by category for each period, and joined the category translation table to display English labels.

There were 70 distinct non-null categories in 2017 and 72 in 2018. This is a net difference, not proof that exactly two categories appeared. A year/category table contains repeated category names across years, and a null-category sales group can produce an additional row.

The recovered category output reconciles to R$ 6,164.76 for categories present in 2018 and absent in 2017: `portateis_cozinha_e_preparadores_de_alimentos` (R$ 3,968.53), `fraldas_higiene` (R$ 1,356.69), and `flores` (R$ 839.54). This is approximately 0.14% of the overall sales increase. One category, `seguros_e_servicos`, disappears, explaining the net increase from 70 to 72. The sum of all category rows, including NULL-category rows, matches the overall sales total in each year. The original reconciliation used historical rows. On 15 October 2026, category counts, the three appearing-category amounts, and the disappearing category were also confirmed by rerunning the corresponding queries in SSMS. The untranslated R$ 3,968.53 category must be retained when joining the translation table.

The investigation then moved to individual product references and their sales by year. Distinct sold references increased from 9,859 to 20,495. I still need to archive the detailed product-level query and its output before drawing conclusions about individual products.

### 4. Compare buyers and active sellers

[Buyer and product queries](sql/04_buyers_and_products.sql)

Unique buyers increased from 22,320 to 52,743, using `customer_unique_id`. Active sellers increased from 1,227 to 2,383. These are period activity counts: the difference does not measure newly recruited sellers or distinguish entry, reactivation, and inactivity.

### 5. Compare seller states and measure their sales

[Seller and state queries](sql/05_sellers_and_states.sql)

The analysis counted represented seller states, listed active sellers by state and year, and built a side-by-side comparison using conditional aggregation. MA, PA, and PI appeared in 2018 with one active seller each, while AM had one in 2017 and none in 2018.

Item sales were then calculated by seller state for both periods. The three appearing states contributed:

| Seller state | Janâ€“Aug 2017 item sales (R$) | Janâ€“Aug 2018 item sales (R$) |
| --- | ---: | ---: |
| MA | 0.00 | 36,408.95 |
| PA | 0.00 | 238.00 |
| PI | 0.00 | 2,522.00 |
| **Total** | **0.00** | **39,168.95** |

This is approximately 0.92% of the overall sales increase, or 0.53% of total 2018 item sales. Their contribution was therefore already investigated and was small relative to overall growth. This concerns seller locations, not customer-market expansion.

### 6. Identify SP's weight and investigate it further

[SP product and city queries](sql/06_sp_products_and_cities.sql)

| SP indicator | Janâ€“Aug 2017 | Janâ€“Aug 2018 |
| --- | ---: | ---: |
| Active sellers | 723 | 1,417 |
| Item sales (R$) | 2,016,153.52 | 4,798,484.69 |
| Share of overall item sales | 64.77% | 64.97% |

SP accounted for approximately 65.12% of the overall sales increase. **SP here is the state of SÃ£o Paulo, not just the city of SÃ£o Paulo.** These are provisional geographic allocations based on the recorded seller states; their sensitivity to unresolved geographic inconsistencies has not been measured.

The next hypotheses concerned assortment expansion within SP and a larger seller network. I explored distinct product references sold by SP sellers. My notes describe a doubling, but I still need the exact query and output to verify this figure. Neither a product-attractiveness explanation nor a distribution strategy has been established.

### 7. Compare seller cities within SP and identify data-quality issues

[SP product and city queries](sql/06_sp_products_and_cities.sql)

Before continuing the SP product comparison, the investigation counted distinct recorded city names for active SP sellers and compared names present in only one period. An older chat message reported 151 in 2017 and 258 in 2018. The latest SSMS query on 15 October 2026 returned **151 and 228**. Cleaning remains in progress; these are provisional labels, and the reason for the discrepancy has not been established. These are unstandardized labels, not validated counts of municipalities or proof of geographic expansion.

The lists exposed spelling variants, abbreviations, encoding problems, and possible city/state inconsistencies. This prompted work on city-name standardization and postal-prefix checks. Later counts of 147 and 209, and a reference to 55 appearing cities, occur during that quality-work stage and cannot be treated as equivalent to the original raw counts without recovering the exact query definitions. I have not yet verified the sales contribution of those 55 city labels. The small contribution demonstrated above concerns MA, PA, and PI, not those city labels.

City-cleaning previews using `CASE` were explored. A transformed query result alone does not prove that source rows were updated. The investigation remains ongoing, and final business recommendations have not been developed.

## Seller Geographic Consistency Check

[Geographic consistency query](sql/07_seller_geographic_check.sql)

After the overall period comparison and the comparison of active seller states, a geographic consistency check was performed on the full sellers table, rather than only sellers active in either comparison period.

The check compares each seller's recorded state with a reference state derived from the seller's ZIP code prefix in `geolocation`. The reference is the most frequent state for that prefix, using state code order to break frequency ties. This is a consistency rule, not an independently verified address reference.

| Geographic status | Sellers |
| --- | ---: |
| CONSISTENT | 3,053 |
| INCONSISTENT | 35 |
| NOT_FOUND | 7 |
| **Total** | **3,095** |

`CONSISTENT` means the recorded seller state matches the derived reference state. `INCONSISTENT` means the states differ. `NOT_FOUND` means no non-null reference state was available through the ZIP-prefix lookup; it does not establish that the seller's address is invalid.

The original 3,095-row geographic output has now been recovered and preserved in the archive, with 3,095 distinct seller IDs. Its original labels are COHERENT (3,053), INCOHERENT (35), and NON TROUVE (7), matching the English summary. The linked query was corrected/reconstructed and still needs a fresh SQL Server run. The 35 mismatches and 7 cases without a reference remain unresolved: **no geographic corrections have been applied**. A mismatch alone does not identify which source is wrong. The impact on the previously reported seller-state comparison has not yet been assessed.

[Download the recovered outputs and provenance](requetes-et-resultats-olist.zip).

## Verification update — 15 October 2026

[Executed queries](sql/08_verified_queries_2026_10_15.sql) · [Result transcriptions](VERIFIED_RESULTS_2026_10_15.md). Only the checks listed in that record are confirmed as rerun. Historical geographic output is preserved, and geographic anomalies remain unresolved.

## Query presentation correction

The main README now links to the separate, rerun queries rather than presenting reconstructed extensions as the original workflow. The sales/order CTE proposed for Episode 2 Part 2 was not used for the original results and was not published. The author subsequently supplied three separate original queries: distinct order count, item sales through an INNER JOIN, and item sales per order through a LEFT JOIN with COUNT(DISTINCT) and ROUND. Those three queries now form the Episode 2 script, with their supplied logic preserved. Category CTEs and the geographic ranking method remain guided checks to revisit, with their execution/provenance distinguished from independent mastery. Earlier drafts remain in Git history and the historical archive.

## Author-supplied Episode 2 queries

[Three separate queries](sql/02_sales_and_orders.sql) replace the previous presentation of the period-comparison script. The third query calculates the per-order ratio directly using a LEFT JOIN and ROUND; it is not a CTE or a calculation using hard-coded totals. No new database run was performed for this source update. Other query files remain unchanged and will be reviewed as the project advances.


## Series update - 18 October 2026 (Episodes 4 to 6)

All comparisons use January-August 2017 vs January-August 2018. Item sales = SUM(price), freight excluded, no order-status filter; not Olist's official revenue. These are descriptive comparisons and do not establish causes.

### Episode 4 - Category contribution

[Script](sql/10_category_contribution.sql). Item sales rose by R$ 4,272,905.48. Three categories with sales in 2018 and none in 2017 accounted for R$ 6,164.76 (0.14% of the increase). The top 10 categories accounted for 67.5% of the increase; 59 of 73 categories recorded higher sales in 2018. Contribution mixes category size and growth speed.

### Episode 5 - Products

[Script](sql/11_product_turnover.sql). Distinct product IDs sold rose from 9,859 to 20,495 (counts of distinct product_id, not units). 27,918 product IDs sold in at least one window: 2,436 in both, 18,059 in 2018 only, 7,423 in 2017 only. Of the 20,495 products sold in 2018, 15,500 (75.6%) had no recorded sale before 2018 and generated R$ 4,490,754.07 (60.8% of 2018 item sales). "No recorded sale" does not establish that a product is new.

### Episode 6 - Sellers

[Script](sql/12_seller_analysis.sql) - [visuals](images/episode-6/). Active sellers (at least one recorded order item in the window) rose from 1,227 to 2,383 (+94.2%). Average item sales per seller: R$ 2,537.08 then R$ 3,099.41; median: R$ 607.10 then R$ 782.24. Total item sales rose 137.3%; the rise in sellers (x1.94) weighed more than the rise in average sales per seller (x1.22). Sales bands (analyst-chosen thresholds): sellers under R$ 1,000 were 55.5% of 2018 sellers and 6.1% of item sales; the 63 sellers (2.6%) at R$ 20,000 or more accounted for 37.2% of item sales (25 sellers and 29.8% in 2017).

Seller state (registered) by sales band was also checked: about 57-62% of sellers in the first three bands are in SP in both windows; in the top band SP held 20 of 25 sellers in 2017 and 40 of 63 in 2018. This cross-check is kept for the geography episodes and relies on the registered seller state only. Seller city data still needs cleaning, so no city-level conclusion is drawn.

Open questions: whether 2018 sellers were the same as in 2017 (686 sellers active in both windows in the January-August data; earlier history before 2018 still to be tested), and whether products with no earlier recorded sale came from sellers with no earlier recorded sale.

### Episode 7 - Seller continuity

[Script](sql/13_seller_continuity.sql) - [visuals](images/episode-7/). 686 of the 2,383 sellers active in January-August 2018 (28.8%) were also active in January-August 2017; 1,697 were active in the 2018 window but not in the 2017 window and 541 of the 1,227 sellers of 2017 had no sale in the 2018 window. The 686 made 82.8% of 2017 item sales and 49.7% of 2018 item sales. 1,284 sellers active in 2018 (53.9%) had no recorded sale before 2018 and made R$ 2,214,796.80 (30.0%) of 2018 item sales; the other 1,099 had sold before 2018 (including 413 who were absent from the January-August 2017 window). Share of 2017 sellers active again in 2018, by 2017 sales band: 43.1% / 70.8% / 85.5% / 92.0% (749 / 322 / 131 / 25 sellers). Among the 686, 214 moved to a higher band, 339 stayed in the same band and 133 moved to a lower band; of the 63 sellers in the 2018 top band, 33 came from the 686 and 30 were active in 2018 only.

Registered seller state of the three groups was also checked (executed in SSMS; per-state totals tie to the validated state table): the 686 are spread over 17 states with SP at 57.3% and the Southeast at 73.2%, close to the distribution of all sellers. Seller city data still needs cleaning, so no city-level conclusion is drawn.

## Series update - 19 October 2026 (Episode 8)

### Episode 8 - Where were the sellers?

[Script](sql/14_seller_geography_check.sql) - [visuals](images/episode-8/). Active sellers by registered region (Southeast = SP, MG, RJ, ES; South = PR, SC, RS): 909 / 267 / 51 other in 2017 (1,227) and 1,752 / 513 / 118 other in 2018 (2,383); Southeast + South = 95.8% and 95.0%. SP held 723 of 1,227 sellers (58.9%) and 1,417 of 2,383 (59.5%); SP accounted for about 65% of item sales in both windows (64.77% and 64.97%, validated state table).

ZIP-code consistency check (all 3,095 sellers; one row per seller, 3,095 distinct IDs): CONSISTENT 3,053, INCONSISTENT 35, NOT_FOUND 7. Item sales of the 42 flagged sellers: R$ 22,818.61 in 2017 (0.73%) and R$ 42,065.65 in 2018 (0.57%); the three statuses tie to R$ 3,113,000.32 and R$ 7,385,905.80. Of the 35 INCONSISTENT sellers, 33 were registered in SP (reference state PR 10, SC 7, MG 6, RJ 4, RS 3, ES 1, BA 1, DF 1) and two were registered elsewhere (PA with reference PR, RN with reference RJ). The maximum effect on SP of reclassifying every flagged SP-registered seller is about 0.6 percentage points of item sales. The rule compares each registered state with the most frequent state of its ZIP prefix; it is an internal consistency check, and no state was corrected.

City labels: 611 distinct labels in the sellers table, still 611 after LOWER/LTRIM/RTRIM (SQL Server's default comparison ignores case and trailing spaces, so this does not prove that case is clean). Sao Paulo appears as 7 labels covering 705 sellers (694 + 4 + 3 + 1 + 1 + 1 + 1); 9 other labels containing "sao paulo" or "sp" appear to refer to different places (auriflama/sp, carapicuiba / sao paulo, jacarei / sao paulo, maua/sao paulo, mogi das cruzes / sp, ribeirao preto / sao paulo, santo andre/sao paulo, sao sebastiao da grama/sp, sbc/sp); a naive rule "label contains sao paulo" would merge them into the city of Sao Paulo. Reading "sp" as the city of Sao Paulo is an interpretation. The earlier city-label cleaning (151 to 147 to 142 in 2017, 228 to 209 to 197 in 2018) was performed with CASE expressions inside a CTE, without modifying the sellers table (verified: sellers still holds 3,095 rows and 1,849 SP sellers). Chapter 2 will restart the cleaning from the raw data.

Idea kept for Chapter 2 (after cleaning): sellers and item sales per city by region, using the median rather than the mean (Sao Paulo holds about 700 sellers), and a split of the sales increase between cities already active in 2017 and cities active only in 2018.

Series update - 19 October 2026 (Episode 9)

[Script](sql/15_buyer_repeat_categories.sql) - [visuals](images/episode-9/). Buyers = customer_unique_id, January-August windows, no order-status filter. Single-order buyers: 21,733 of 22,320 (97.4%) in 2017 and 51,586 of 52,743 (97.8%) in 2018. Everyday-use categories (analyst grouping of 8 categories): item sales R$ 499,901.04 (16.1%) in 2017 and R$ 1,383,133.74 (18.7%) in 2018; other categories R$ 2,613,099.28 and R$ 6,002,772.06 (totals tie to R$ 3,113,000.32 and R$ 7,385,905.80). Buyers with 2+ orders in the same group: everyday-use 69 of 3,563 (1.94%) then 111 of 10,143 (1.09%); other 472 of 18,589 (2.54%) then 886 of 42,664 (2.08%). Follow-up of buyers first recorded in Jan-Mar 2017 (orders over the whole dataset): 5,152 buyers, 261 ordered again (5.07%). Wording kept descriptive: everyday-use buyers did not show a higher repeat-order rate within the same group; the cohort rate and window rates cover different buyers, so only orders of magnitude are compared. Queries re-run in SSMS on 19 Oct 2026 after the original scripts were lost; results identical to the earlier runs.

## Series update - 20 October 2026 (Chapter 2, Steps 1 to 3)

Scripts: [audit](sql/16_chapter2_geography_audit.sql) - [mapping table](sql/17_seller_city_map.sql) - [checks and seller geography](sql/18_chapter2_checks_and_seller_geography.sql). Same windows and item-sales definition as Chapter 1 (January-August, SUM(price), freight excluded, no order-status filter unless stated). Every query was run in SSMS by the analyst and every result tied to the validated totals before being used. Descriptive only; no causal claim.

Plan fixed for Chapter 2: (1) clean cities and states, (2) recalculate key figures and control by order status, (3) weight of Sao Paulo (city and state), seller and buyer side, (4) what distinguishes Sao Paulo (basket, categories, freight), (5) delivery times crossed with seller and buyer location, (6) conclusion. Chapter 3: why buyers did not come back (order status, reviews and comments, delays, link with repeat orders). Steps 1 to 3 (seller side) are done.

Step 1. Labels: sellers 611 labels / 636 city+state pairs; customers 4,119 / 4,310. Customers: 54 labels with apostrophes or hyphens are genuine names; 163 names appear under 2-4 states (142 / 14 / 7), which accounts for exactly 191 extra pairs (homonyms, not spelling variants); 60 labels (76 rows, 0.08%) absent from the ZIP reference are small localities, left as is. Sellers: 26 labels (29 sellers) with non-letter characters to treat; 94 labels (103 sellers, 3.3%) absent from the reference, classified through the ZIP prefix of each seller (most frequent city per prefix, ROW_NUMBER) into 55 text errors with agreeing state, 32 valid cities with a different registered state (30 in SP), 14 unusable or ambiguous labels and 2 reference quirks. Four rules agreed: explicit mapping table for corrections, unresolved status without guessing, originals kept for reference quirks, and (rule 5) valid labels whose ZIP points to another municipality kept as registered (26 sellers, 12 of them "sao paulo").

Mapping table (dbo.seller_city_map): 56 corrected labels (66 sellers), 15 unresolved (18), 2 kept; checks A, B and C tied (C: 0 rows); labels 611 -> 548 and pairs 636 -> 572 (unresolved excluded). Process notes kept for transparency: the first versions failed on a reserved word (renamed column) and on batch compilation (GO added); control B caught that marking "rio bonito" unresolved for every state would have wiped a valid seller registered in RJ, so the rule now applies to SP only (a state column in the mapping key); a complementary check found the reference table itself contains non-standard spellings (for example "santa barbara d oeste"), so a match with the reference is not proof of a correct label, and added three missed corrections (two hyphenated names and one duplicated-name label) plus "sp" as unresolved. An e-mail address typed into a city field is matched by pattern in the published script instead of being written out. The published script differs from the executed version 5 only in that pattern match and in its header comments.

Step 2. SP share of item sales: 64.77% / 64.97% (registered state) vs 64.22% / 64.57% (ZIP-based state); share of the increase 65.12% vs 64.82%. 33 SP-registered sellers point elsewhere by ZIP (PR 10, SC 7, MG 6, RJ 4, RS 3, DF 1, BA 1, ES 1; R$ 16,859.70 in 2017 and R$ 29,693.69 in 2018), none points into SP; ties to Episode 8 (33 SP-registered INCONSISTENT sellers, R$ 16,859.70 in 2017; the R$ 290.00 gap in 2018 belongs, by subtraction, to the two inconsistent sellers registered outside SP). Order-status control: delivered 21,998 / 52,783 orders (95.8% / 97.8%), item sales R$ 2,993,456.13 / 7,218,125.12 (96.2% / 97.7%); item sales +141.1% over delivered orders vs +137.3% over all statuses; non-delivered orders 970 (4.2%) and 1,208 (2.2%); "unavailable" orders (235 / 145) have no items; canceled orders carry R$ 32,149.51 / 44,868.39 of item sales; 330 orders of 2017 still show "shipped" (reason unknown).

Step 3 (seller side). Four disjoint groups (city from the mapping table): city of Sao Paulo 289 / 522 active sellers, R$ 640,912.71 / 1,488,974.01; SP state with unresolved city 4 / 8, R$ 2,372.36 / 27,063.56; other SP cities 430 / 887, R$ 1,372,868.45 / 3,282,447.12; other states 504 / 966, R$ 1,096,846.80 / 2,587,421.11. Contribution to the R$ 4,272,905.48 increase: city of Sao Paulo 19.85%, other SP cities 44.69%, unresolved 0.58%, other states 34.88% (SP state total 65.12%). Top 15 cities contribute 54.1% of the increase (ten in SP, plus Curitiba, Maringa, Rio de Janeiro, Teresopolis, Recife). Guariba has one active seller in each window and 2.64% of the increase; Teresopolis has no recorded sale in 2017; Ibitinga's mean sales per seller fell from R$ 12,036 to R$ 6,435 while its sellers tripled (means only).

Open points: customers' state is not yet compared with their ZIP prefix; medians per city and the same analysis on the buyer side are still to do; the 12 "sao paulo" sellers whose ZIP points to another municipality and the 8 unresolved 2018 sellers of the SP state are small but untested sensitivities for the city-level share; "sbc" read as Sao Bernardo do Campo is an interpretation; the ZIP reference is an internal consistency rule, not address verification.
