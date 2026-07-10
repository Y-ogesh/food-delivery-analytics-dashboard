# Data Profiling Report

## Project

**Project:** Food Delivery Analytics Dashboard

**Dataset:** Food Delivery Order History Dataset

**Source:** Kaggle

---

# Objective

The objective of this data profiling exercise is to understand the structure, quality, and completeness of the dataset before performing any business analysis. This process helps identify missing values, duplicate records, data types, and potential data quality issues.

---

# Dataset Overview

| Metric | Value |
|---------|------:|
| Total Orders | 21,321 |
| Total Columns | 29 |
| Total Restaurants | 21 |
| Total Customers | 11607 |
| Total Cities | 1 |

### Observation

The dataset contains 21 restaurants serving over 11,000 unique customers within a single city. This indicates that the dataset represents a localized food delivery platform rather than a nationwide service.
---

# Schema Inspection

The dataset contains information related to:

- Restaurant information
- Customer information
- Order information
- Financial information
- Delivery information
- Customer feedback

The schema was inspected using PostgreSQL to understand the available columns and their respective data types.

---

# Data Quality Assessment

## Ratings Completeness

| Metric | Value |
|---------|------:|
| Total Orders | 21,321 |
| Ratings Present | 2491 |
| Ratings Missing | 18830 |
| Rating Completion (%) | 11.68% |

### Observation

Only 11.68% of orders contain customer ratings. This suggests that customer feedback is optional and that rating-based analyses should be interpreted carefully, as they represent only a subset of all completed orders.

---

## Order Status Distribution


| order_status | total_orders |
| ------------ | -----------: |
| Delivered    |       18,532 |
| Cancelled    |        2,104 |
| Rejected     |          685 |


### Observation

Approximately 87% of orders were successfully delivered, while the remaining orders were either cancelled or rejected. This indicates that most orders reached successful completion, although cancellation and rejection trends should be investigated further to identify potential operational improvements.

---

## Duplicate Order IDs

### Result

- Number of duplicate Order IDs: 0 

### Observation

Since no duplicate Order IDs were found, Order ID can be considered a reliable primary identifier for future analysis.

---

## Dataset Date Range

| Metric | Value |
|---------|------:|
| Earliest Order | 01:00 AM, December 08 2024 |
| Latest Order | 12:59 PM, October 30 2024 |


### Observation

The `order_placed_at` column is currently stored as text, so the earliest and latest values cannot yet be determined accurately. This column will be converted to a proper timestamp during the data cleaning phase before performing time based analysis.

---

# Initial Business Observations

Based on the profiling results:

- The dataset supports restaurant performance analysis through order and revenue metrics.
- Customer identifiers enable repeat customer and retention analysis.
- Financial columns allow revenue, discount, and average order value calculations.
- Delivery-related fields enable operational efficiency analysis, including rider wait time and kitchen preparation time.
- Customer ratings and reviews provide opportunities for satisfaction analysis, although rating coverage is limited.

---

# Data Quality Issues Identified

The following issues were identified during profiling and will be addressed during the data cleaning phase:

- `order_placed_at` is stored as text instead of a timestamp.
- Customer ratings are missing for most orders.
- Date fields require conversion before time-based analysis.
- Additional validation of financial and delivery-related fields will be performed.

--- 

# Next Steps

The next phase of the project will focus on:

- Data Cleaning
- Data Type Conversion
- Handling Missing Values
- Preparing the dataset for SQL-based business analysis