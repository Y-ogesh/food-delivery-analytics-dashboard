# Data Profiling Report

## Project

**Project:** Food Delivery Analytics Dashboard

**Dataset:** Food Delivery Order History Dataset

**Source:** Kaggle

---

## Objective

The objective of this data profiling exercise is to understand the structure, quality, and completeness of the dataset before performing business analysis. This process helps identify missing values, duplicate records, data type issues, and potential data quality risks.

---

## Dataset Overview

| Metric | Value |
|---------|------:|
| Total Orders | 21,321 |
| Total Columns | 29 |
| Total Restaurant Locations | 21 |
| Total Restaurant Brands | 6 |
| Total Customers | 11,607 |
| Total Cities | 1 |
| Total Subzones | 8 |

### Observation

The dataset contains 21 restaurant locations across 6 restaurant brands, serving over 11,000 unique customers within one city region.

The source data contains `Delhi NCR` as the only city value. This project is therefore framed as a general food delivery analytics project using Delhi NCR order activity. The raw geography should be preserved and should not be rewritten to represent another city.

---

## Schema Inspection

The dataset contains information related to:

- Restaurant information
- Customer information
- Order information
- Financial information
- Delivery information
- Customer feedback

The schema was inspected using PostgreSQL to understand the available columns and their respective data types.

---

## Data Quality Assessment

### Ratings Completeness

| Metric | Value |
|---------|------:|
| Total Orders | 21,321 |
| Ratings Present | 2,491 |
| Ratings Missing | 18,830 |
| Rating Completion (%) | 11.68% |

### Observation

Only 11.68% of orders contain customer ratings. This suggests that customer feedback is optional and that rating-based analyses should be interpreted carefully because they represent only a subset of all orders.

---

### Order Status Distribution

| Order Status | Total Orders | Order Percentage |
| ------------ | -----------: | ---------------: |
| Delivered | 21,131 | 99.11% |
| Rejected | 158 | 0.74% |
| Returned | 25 | 0.12% |
| Picked up | 3 | 0.01% |
| Return cancelled | 3 | 0.01% |
| Timed out | 1 | 0.00% |

### Observation

Approximately 99.11% of orders were delivered. Non-delivered outcomes are rare in this dataset, with rejected orders representing the largest exception group. Because these exception categories are small, later operational analysis should use both counts and percentages to avoid overstating small-volume issues.

---

### Duplicate Order IDs

| Metric | Value |
|---------|------:|
| Duplicate Order IDs | 0 |

### Observation

No duplicate order IDs were found. `order_id` can be treated as a reliable unique order identifier for this project.

---

### Dataset Date Range

| Metric | Value |
|---------|------:|
| Earliest Order | 2024-09-01 00:13 |
| Latest Order | 2025-01-31 23:59 |

### Observation

The `order_placed_at` column is stored as text in the raw table. Raw text sorting produced misleading date range results, so the field was parsed with PostgreSQL's `to_timestamp()` function to determine the correct range. This conversion should be included in the cleaned staging layer before any time-based analysis.

---

### Feedback and Issue Completeness

| Metric | Value |
|---------|------:|
| Reviews Present | 296 |
| Customer Complaint Tags Present | 469 |
| Cancellation / Rejection Reasons Present | 186 |

### Observation

Feedback, complaint, and cancellation/rejection fields are sparsely populated. These columns are still useful for issue analysis, but they should not be interpreted as complete measures of all customer dissatisfaction or operational problems.

---

## Initial Business Observations

Based on the profiling results:

- The dataset supports restaurant location performance analysis through order and revenue metrics.
- Customer identifiers enable repeat customer and retention analysis.
- Financial columns allow revenue, discount, and average order value calculations.
- Delivery-related fields enable operational efficiency analysis, including rider wait time and kitchen preparation time.
- Customer ratings and reviews provide opportunities for satisfaction analysis, although rating coverage is limited.
- Geographic analysis is limited because all records are from Delhi NCR.

---

## Data Quality Issues Identified

The following issues were identified during profiling and will be addressed during the data cleaning phase:

- `order_placed_at` is stored as text instead of a timestamp.
- Raw text date sorting produces incorrect date range results.
- `distance` is stored as text and must be converted before distance-based analysis.
- Customer ratings are missing for most orders.
- Feedback and issue fields are sparsely populated.
- The dataset represents Delhi NCR food delivery activity and should not be described as location-specific to another city.
- Additional validation of financial and delivery-related fields will be performed.

---

## Next Steps

The next phase of the project will focus on:

- Data cleaning
- Data type conversion
- Handling missing values appropriately
- Preparing a cleaned staging layer for SQL-based business analysis
