# Food Delivery Analytics Dashboard

## Project Overview

The **Food Delivery Analytics Project** is a production-style analytics portfolio project focused on understanding restaurant performance, order outcomes, customer behavior, delivery operations, and revenue patterns from food delivery order history data.

The goal of this repository is to demonstrate professional data analyst and analytics engineering skills using SQL, PostgreSQL, documentation, and eventually Power BI dashboarding.

## Dataset Source and Geography

**Dataset:** Food Delivery Order History Dataset  
**Source:** Kaggle  
**Current Raw Table:** `raw_order_history`  
**Geography Represented:** Delhi NCR

The dataset contains food delivery activity from `Delhi NCR`. The source data should remain truthful to its actual geography. Restaurant names, city values, subzones, and other location-related fields are preserved as provided in the raw dataset.

The local repository folder name has not been changed yet, but the project documentation is now framed consistently as a general food delivery analytics project.

## Business Objectives

This project is designed to answer practical business questions such as:

- How many orders were placed, delivered, rejected, returned, or otherwise not completed?
- Which restaurant locations and brands generate the most order volume and revenue?
- What are the main drivers of operational performance, such as kitchen preparation time and rider wait time?
- How complete and reliable are customer feedback fields such as ratings, reviews, and complaints?
- How do discounts, packaging charges, and order totals support financial analysis?
- What cleaned and documented data model should feed a future dashboard?

## Tech Stack

- PostgreSQL
- SQL
- DataGrip
- VS Code
- Git and GitHub
- Power BI, planned
- Python, optional later if needed

## Repository Structure

```text
docs/
  data_dictionary.md
  data_profiling_report.md

sql/
  01_database_setup.sql
  02_data_profiling.sql
  03_data_cleaning.sql
  04_business_analysis.sql
  05_advanced_sql.sql

data/
  order_history_kaggle_data.csv

dashboard/
images/
notebooks/
README.md
```

## Current Progress

- PostgreSQL database created
- Raw table created
- CSV imported into `raw_order_history`
- Data profiling SQL completed
- Profiling report reconciled with live database results
- Data dictionary drafted for the raw dataset
- Data cleaning, business analysis, advanced SQL, and dashboarding are planned next

## Key Profiling Findings

- Total orders: 21,321
- Total columns: 29
- Restaurant locations: 21
- Restaurant brands: 6
- Unique customers: 11,607
- Cities represented: 1, `Delhi NCR`
- Subzones represented: 8
- Rating completion rate: 11.68%
- Duplicate order IDs found: 0
- Parsed order date range: 2024-09-01 00:13 to 2025-01-31 23:59
- Delivered orders represent 99.11% of all records

## Data Quality Notes

- `order_placed_at` is stored as text in the raw table and must be converted to a timestamp for time-based analysis.
- `distance` is stored as text and must be converted before distance-based analysis.
- Ratings, reviews, complaints, and cancellation/rejection reasons are sparsely populated.
- `restaurant_id` should be used as the restaurant location key because multiple locations can share the same restaurant name.
- The dataset represents Delhi NCR food delivery activity and should not be described as location-specific to any other city.

## Planned Next Steps

1. Build a cleaned staging layer in `sql/03_data_cleaning.sql`.
2. Convert text fields such as order timestamp and distance into analysis-ready data types.
3. Add data quality validation queries for cleaned fields.
4. Define business metrics for orders, revenue, delivery performance, and customer feedback.
5. Create analytical SQL views for dashboard consumption.
6. Build a Power BI dashboard using the cleaned analytical layer.
