# SSMS Verification — 15 October 2026

[Project overview](README.md) · [Queries executed](sql/08_verified_queries_2026_10_15.sql)

The analyst executed the queries in SSMS against the `olist` database and copied the outputs into the project conversation on 15 October 2026. The tables below transcribe those outputs; they are not direct file exports from SSMS. Percentages are calculated from the confirmed amounts. Only the checks listed here were rerun.

## 1. Order identifier validation

| Total rows | Non-null order IDs | Distinct order IDs |
| ---: | ---: | ---: |
| 99,441 | 99,441 | 99,441 |

Every order ID in the checked table is non-null and unique. On this table, `COUNT(*)`, `COUNT(order_id)` and `COUNT(DISTINCT order_id)` therefore give equivalent order counts. This does not validate uniqueness in the other tables.

## 2. Period comparison

Purchase periods: January–August 2017 and January–August 2018. No order-status filter; item sales exclude freight.

| Metric | 2017 | 2018 |
| --- | ---: | ---: |
| Distinct orders | 22,968 | 53,991 |
| Item sales (R$) | 3,113,000.32 | 7,385,905.80 |
| Unique buyers | 22,320 | 52,743 |
| Sold product references | 9,859 | 20,495 |
| Active sellers | 1,227 | 2,383 |
| Active seller states | 19 | 21 |
| Distinct non-null categories sold | 70 | 72 |

Item sales increased by R$ 4,272,905.48 (+137.26%); orders increased by 31,023 (+135.07%). Item sales per recorded order were approximately R$ 135.54 and R$ 136.80. This ratio uses all recorded orders in the period, including those without item rows; it is not a delivered-order or paid-order average.

## 3. Appearing and disappearing categories

The rerun found these categories in 2018 and absent in the 2017 window:

| Category | 2018 item sales (R$) |
| --- | ---: |
| portateis_cozinha_e_preparadores_de_alimentos | 3,968.53 |
| fraldas_higiene | 1,356.69 |
| flores | 839.54 |
| **Total** | **6,164.76** |

The total was repeated on each row by the window function; it is counted once. It represents about 0.1443% of the overall sales increase. A separate EXCEPT query returned `seguros_e_servicos` as present in 2017 and absent in 2018. Three appearances minus one disappearance explain the net gain of two categories. These are appearances within the comparison windows, not verified launch dates.

The full translated category-sales table has not been rerun as part of this verification.

## 4. Sellers and item sales by state

| State | Active sellers 2017 | Active sellers 2018 | Item sales 2017 (R$) | Item sales 2018 (R$) |
| --- | ---: | ---: | ---: | ---: |
| AM | 1 | 0 | 1,177.00 | 0.00 |
| BA | 6 | 17 | 53,329.28 | 74,588.20 |
| CE | 3 | 11 | 6,375.42 | 12,698.92 |
| DF | 16 | 25 | 23,245.67 | 45,756.61 |
| ES | 4 | 20 | 14,778.30 | 22,309.13 |
| GO | 11 | 34 | 18,427.52 | 36,330.25 |
| MA | 0 | 1 | 0.00 | 36,408.95 |
| MG | 117 | 183 | 280,848.04 | 498,310.72 |
| MS | 2 | 3 | 4,147.79 | 2,505.10 |
| MT | 2 | 4 | 286.24 | 9,202.68 |
| PA | 0 | 1 | 0.00 | 238.00 |
| PB | 3 | 5 | 4,529.49 | 7,178.51 |
| PE | 2 | 8 | 4,571.69 | 83,149.37 |
| PI | 0 | 1 | 0.00 | 2,522.00 |
| PR | 149 | 266 | 286,202.57 | 728,304.47 |
| RJ | 65 | 132 | 144,937.66 | 490,518.89 |
| RN | 2 | 5 | 4,541.40 | 1,592.50 |
| RO | 2 | 1 | 3,788.04 | 174.80 |
| RS | 42 | 99 | 83,728.53 | 205,866.69 |
| SC | 76 | 148 | 161,722.36 | 329,224.72 |
| SE | 1 | 2 | 209.80 | 540.60 |
| SP | 723 | 1,417 | 2,016,153.52 | 4,798,484.69 |

Both complete state tables were rerun and matched the historical rows. State sales reconcile exactly to total item sales. MA, PA and PI contribute R$ 39,168.95, about 0.92% of the overall increase. SP accounts for 64.77% and 64.97% of period sales and 65.12% of the increase.

Geographic allocations use recorded seller states. Their arithmetic is confirmed, but their geographic accuracy remains subject to unresolved seller-location anomalies.

## 5. SP city labels — provisional

| Purchase year | Distinct recorded city labels |
| --- | ---: |
| 2017 | 151 |
| 2018 | 228 |

These are the results of the latest query supplied by the analyst. Cleaning is in progress and these are not final counts of validated municipalities. An older chat message reported 258 for 2018; that value is retained only as historical context. The cause of the difference has not been established. Do not attribute the change to completed cleaning or use it as evidence of geographic expansion.

## Not covered by this rerun

- Monthly volumes were recovered from historical outputs, not rerun here.
- The full category-sales/translation table and product-level sales comparison were not rerun.
- Exact SP product-reference counts and the appearing/disappearing city lists remain to be checked.
- The geographic consistency classification (3,053 / 35 / 7) is supported by the recovered historical output, not a new rerun in this sequence.
- No geographic corrections are reported as applied. City-label cleaning remains in progress.

## Data attribution

Derived from the [Brazilian E-Commerce Public Dataset by Olist](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce). These result summaries are shared under [CC BY-NC-SA 4.0](https://creativecommons.org/licenses/by-nc-sa/4.0/). Independent portfolio project; no affiliation with Olist.
