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

The analysis began with an overall comparison of sales performance, buyers, products, and sellers. The next stage is to examine sales trends and segments to better understand the observed growth and identify potential areas of underperformance.

Further investigations may include product categories, sellers, customers, geographic patterns, delivery performance, and customer satisfaction, depending on the findings.

### Metric Definitions

- **Item sales (CA in the analysis):** `SUM(order_items.price)` in Brazilian reais (R$), excluding freight. This measures the value of items sold, not Olist's accounting revenue, profit, or total payments.
- **Orders:** distinct `order_id` values in `orders` during each period.
- **Unique buyers:** distinct `customers.customer_unique_id` values linked to orders during each period, rather than distinct `customer_id` values.
- **Sold product references:** distinct `product_id` values in order items during each period, not units sold or product categories.
- **Active sellers:** distinct sellers with at least one order item during each period.
- **Seller states:** distinct `sellers.seller_state` values for active sellers. These describe seller locations, not buyer locations or delivery coverage.

No order-status filter is applied. Cancelled or undelivered orders may therefore be included. Orders without items can contribute to order and buyer counts without contributing to item sales.

### Results So Far

The following results were verified during the prior analysis and supplied for this README update. No SQL scripts were executed or revalidated against SQL Server as part of this update.

| Indicator | Jan–Aug 2017 | Jan–Aug 2018 |
| --- | ---: | ---: |
| Item sales (R$) | 3,113,000.32 | 7,385,905.80 |
| Orders | 22,968 | 53,991 |
| Unique buyers | 22,320 | 52,743 |
| Sold product references | 9,859 | 20,495 |
| Active sellers | 1,227 | 2,383 |
| Seller states | 19 | 21 |

Item sales increased by **137.3%**. This growth coincided with more orders, unique buyers, sold product references, and active sellers. These comparisons describe associated changes; they do not yet establish the causes of growth.

Three states appeared among active seller locations in the 2018 comparison period: **MA (Maranhão), PA (Pará), and PI (Piauí)**. **AM (Amazonas)** was represented in 2017 but absent among active seller locations in the 2018 period. The net change was therefore **two additional seller states**, from 19 to 21. This does not establish when sellers joined or left Olist.

The contribution of these states to item sales remains to be investigated. The analysis is ongoing, and final business recommendations have not yet been developed.

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

### Completed

- Database creation
- Creation of 9 tables
- CSV data import
- Data validation
- Initial exploration of the database structure
- Definition of the initial business question and January–August comparison periods
- Overall comparison of item sales, orders, unique buyers, sold product references, and active sellers
- Comparison of active seller states and identification of MA, PA, and PI appearing in 2018 and AM being absent

### In Progress

- Deeper sales performance analysis to understand factors associated with growth
- Investigation of sellers and geographic patterns
- Identification of potential business problems and areas of underperformance

### Next Steps

- Analyze sales trends over time within the January–August comparison periods
- Quantify item sales from sellers in MA, PA, and PI and assess their contribution to growth
- Examine product categories, sellers, and customers to identify growing or underperforming segments
- Investigate potential causes of the patterns identified
- Evaluate delivery performance and customer satisfaction if relevant to the identified problem
- Develop business recommendations based on the findings

## Skills Demonstrated

- SQL Server
- Data preparation
- Relational databases
- Business problem definition
- Exploratory data analysis
- SQL querying
- Business-oriented data analysis
