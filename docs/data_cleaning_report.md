# Data Cleaning Report

## Project

**Project:** Food Delivery Analytics Dashboard  
**Dataset:** Food Delivery Order History Dataset  
**Source Table:** `raw_order_history`  
**Clean Table:** `clean_orders`  
**Geography Represented:** Delhi NCR

---

## Objective

The purpose of this milestone is to transform the immutable raw ingestion table into an analytics-ready staging table. The raw table remains unchanged, while `clean_orders` provides typed, trimmed, and documented fields for future SQL analysis and dashboard development.

---

## Business Purpose

Raw operational data often contains text-formatted dates, text-formatted measures, optional blank fields, and inconsistent whitespace. Cleaning these issues before analysis reduces dashboard errors, improves metric reliability, and makes the project easier for reviewers to understand.

---

## Transformations Performed

| Transformation | Columns Affected | Why It Was Necessary |
|---|---|---|
| Created `clean_orders` from `raw_order_history` | All columns | Preserves raw data while creating an analytics-ready staging layer. |
| Converted order timestamp text to `TIMESTAMP` | `order_placed_at` | Enables correct date filtering, time-series analysis, and dashboard date relationships. |
| Added date and hour attributes | `order_date`, `order_hour` | Simplifies future trend, weekday, and time-of-day analysis. |
| Trimmed leading and trailing whitespace | Text fields | Prevents grouping errors caused by accidental spacing differences. |
| Converted blank strings to `NULL` | Text fields | Preserves missing information consistently instead of treating blanks as real values. |
| Renamed delivery field in cleaned layer | `delivery` to `delivery_method` | Makes the column meaning clearer for analysis. |
| Preserved original distance label | `distance_raw` | Keeps an audit trail for the cleaned numeric conversion. |
| Converted distance text to numeric kilometers | `distance_km` | Enables distance-based aggregation and filtering. |
| Approximated `<1km` as `0.5` km | `distance_km` | Represents orders less than one kilometer away using the documented project assumption. |
| Added primary key constraint | `order_id` | Enforces one cleaned row per order. |

---

## Distance Conversion Logic

The raw `distance` field is stored as text values such as `2km`, `10km`, and `<1km`.

Cleaning rules:

- Values like `2km` are converted to `2.00`.
- Values like `10km` are converted to `10.00`.
- `<1km` is converted to `0.50`.
- Unexpected distance formats would become `NULL` so they can be investigated rather than silently misclassified.

The `<1km` conversion is an approximation and should be described as such in future analysis.

---

## Validation Results

### Row Count Comparison

| Metric | Value |
|---|---:|
| Raw Row Count | 21,321 |
| Clean Row Count | 21,321 |

The row counts match, confirming that the cleaning process did not add or remove records.

### Duplicate Order IDs

| Metric | Value |
|---|---:|
| Duplicate Order ID Groups | 0 |

No duplicate order IDs were found in the cleaned table.

### Important Null Counts

| Field | Null Count |
|---|---:|
| `order_id` | 0 |
| `order_placed_at` | 0 |
| `restaurant_id` | 0 |
| `customer_id` | 0 |
| `order_status` | 0 |
| `distance_km` | 0 |
| `total` | 0 |
| `rating` | 18,830 |
| `review` | 21,025 |
| `customer_complaint_tag` | 20,852 |
| `cancellation_rejection_reason` | 21,135 |

Core analytical fields are complete after cleaning. Feedback and issue fields remain sparse, which is expected based on profiling.

### Date Range Validation

| Metric | Value |
|---|---:|
| Earliest Order | 2024-09-01 00:13 |
| Latest Order | 2025-01-31 23:59 |

The cleaned timestamp field preserves the corrected date range identified during profiling.

---

## Remaining Data Quality Issues

- Ratings are missing for most orders, so rating-based insights should be treated as feedback from a subset of customers.
- Reviews, complaint tags, and cancellation/rejection reasons are sparsely populated.
- `items_in_order` remains a text field and is not yet normalized into item-level rows.
- `discount_construct` remains a text field and may require additional parsing for deeper promotion analysis.
- `<1km` distance values are approximated as `0.5` km rather than exact measured distances.

---

## Next Step

The next milestone should define business metrics and analysis queries using `clean_orders`. Business analysis should not use `raw_order_history` directly unless auditing the raw import.
