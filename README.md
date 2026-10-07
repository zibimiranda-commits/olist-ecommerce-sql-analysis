# Olist E-commerce SQL Analysis

## Project Overview

This project analyzes the Brazilian Olist e-commerce dataset using SQL Server.

The goal is not only to execute SQL queries, but to use data to identify business problems, investigate their causes, and provide actionable recommendations.

## Business Context

Olist has data covering orders, products, customers, sellers, payments, deliveries, and customer reviews.

Before assuming what the main business problem is, the first objective of this project is to understand the company's sales performance and identify potential areas of underperformance.

## Initial Business Question

**How did Olist's sales performance change between January–October 2017 and January–October 2018, and what factors explain this evolution?**

### Analysis Period

An initial exploration of the order data showed that 2016 contains only a limited number of orders, while 2018 data ends in October.

To ensure a fair year-over-year comparison, the main analysis therefore focuses on the same 10-month period: **January to October 2017 vs January to October 2018**.


The analysis will first examine sales performance over time.

If a decline or underperformance is identified, the next step will be to investigate possible causes using the available data, including product categories, sellers, customers, geographic patterns, delivery performance, and customer satisfaction.

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
- Definition of the initial business question

### In Progress

- Sales performance analysis
- Identification of potential business problems

### Next Steps

- Analyze sales trends over time
- Identify periods or segments of underperformance
- Investigate potential causes
- Evaluate delivery performance if relevant to the identified problem
- Develop business recommendations based on the findings

## Skills Demonstrated

- SQL Server
- Data preparation
- Relational databases
- Business problem definition
- Exploratory data analysis
- SQL querying
- Business-oriented data analysis
