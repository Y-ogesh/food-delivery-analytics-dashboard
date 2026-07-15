# Advanced SQL and Analytics Views Report

## Project Scope

Milestone 5 extends the validated baseline business analysis with advanced PostgreSQL techniques and a reusable semantic view layer for future Power BI consumption. Every analysis and view reads from `clean_orders` only. The script does not alter `raw_order_history` or `clean_orders`.

Financial metrics include only rows with `order_status = 'Delivered'`. The `total` field is described as **delivered order value**, not revenue, profit, payout, or an accounting measure.

## Advanced SQL Concepts Demonstrated

| Concept | Analytical use |
|---|---|
| Common Table Expressions | Build readable stages for monthly comparison, customer segmentation, ranking, and operational benchmarks. |
| `RANK` and `DENSE_RANK` | Rank outlets within brands, rank brands, rank high-value customers, and compare rider wait performance. |
| `LAG` | Compare current-month orders and delivered order value with the prior month. |
| Running totals | Calculate cumulative delivered order value by month and cumulative customer value contribution. |
| Moving averages | Smooth daily order volume with a seven-day moving average. |
| Percent-of-total windows | Measure brand, customer segment, value quartile, and individual customer contribution. |
| `NTILE(4)` | Divide customers into delivered-order-value quartiles. |
| Conditional aggregation | Calculate Delivered metrics alongside all-order metrics without misclassifying financial activity. |
| Partitioned windows | Compare outlets within brands and calculate weighted brand operational benchmarks. |
| `CASE` logic | Assign frequency/value labels and faster/slower benchmark statuses. |

## Customer Segmentation Definitions

The segmentation definitions are explicit business rules for this milestone:

### Frequency Segments

- **One-time:** exactly 1 order.
- **Repeat:** 2–4 orders.
- **Loyal:** 5 or more orders.

Frequency segments count all order attempts regardless of final status.

### Value Segments

Customers are ordered by their total delivered order value and assigned with `NTILE(4)`:

- **Q1 (Lowest):** lowest delivered-order-value quartile.
- **Q2:** second quartile.
- **Q3:** third quartile.
- **Q4 (Highest):** highest delivered-order-value quartile.

Customers with no Delivered orders receive zero delivered order value. `customer_id` provides a deterministic secondary sort, but `NTILE` can place customers with equal boundary values in adjacent quartiles to maintain similarly sized groups.

### High-Value Customers

A customer is flagged as high value only when both conditions are true:

- At least 5 **Delivered** orders.
- Membership in **Q4 (Highest)** by delivered order value.

This delivered-order qualification intentionally differs from frequency segments, which use all order attempts.

## Validated Findings

### Restaurant Rankings

- Aura Pizzas ranks first in both demand and delivered order value, with 14,548 total orders and 10,647,191.66 in delivered order value.
- Aura Pizzas contributes 68.23% of total orders and 73.82% of delivered order value.
- Swaad contributes 29.70% of total orders and 24.44% of delivered order value.
- Together, Aura Pizzas and Swaad contribute 97.93% of orders and 98.26% of delivered order value, showing strong portfolio concentration.
- Outlet 20659868 is the highest-value Aura Pizzas outlet and the highest-value outlet overall, with 3,449,430.60 in delivered order value.
- Tandoori Junction ranks fourth in order volume but third in delivered order value, indicating a stronger value mix than Dilli Burger Adda.

### Time-Series Analysis

| Month | Order growth | Delivered-value growth | Cumulative delivered order value |
|---|---:|---:|---:|
| 2024-09 | — | — | 2,595,841.19 |
| 2024-10 | 0.85% | 14.63% | 5,571,346.10 |
| 2024-11 | 5.00% | 0.68% | 8,567,083.23 |
| 2024-12 | -4.23% | 2.31% | 11,632,056.10 |
| 2025-01 | -6.74% | -8.93% | 14,423,379.76 |

- November produced the strongest month-over-month order growth at 5.00%.
- December order volume declined by 4.23%, while delivered order value still grew by 2.31%, indicating a higher-value order mix.
- January recorded declines in both demand and delivered order value.
- The highest complete seven-day moving average was 176.14 daily orders on September 25, 2024. Late November also sustained several of the highest seven-day averages.

### Customer Segmentation

| Frequency segment | Customers | Customer share | Orders | Order share |
|---|---:|---:|---:|---:|
| One-time | 7,713 | 66.45% | 7,713 | 36.18% |
| Repeat | 3,165 | 27.27% | 8,024 | 37.63% |
| Loyal | 729 | 6.28% | 5,584 | 26.19% |

- Loyal customers represent only 6.28% of customers but generate 26.19% of all order attempts.
- One-time customers represent two-thirds of the customer base, highlighting a substantial conversion opportunity.

| Value segment | Customers | Delivered-value range | Delivered order value | Value contribution |
|---|---:|---:|---:|---:|
| Q1 (Lowest) | 2,902 | 0.00–502.95 | 955,849.76 | 6.63% |
| Q2 | 2,902 | 502.95–783.30 | 1,829,593.06 | 12.68% |
| Q3 | 2,902 | 783.30–1,404.90 | 3,031,787.43 | 21.02% |
| Q4 (Highest) | 2,901 | 1,405.95–27,767.93 | 8,606,149.51 | 59.67% |

- Q4 contains approximately one-quarter of customers but contributes 59.67% of delivered order value.
- The high-value definition identifies 698 customers, or 6.01% of the customer base.
- These 698 customers placed 5,372 Delivered orders and contributed 3,472,489.17, equal to 24.08% of all delivered order value.
- The top 20 customers contribute 2.54% of delivered order value, so value concentration is meaningful across a broader customer group rather than depending on only a few individuals.

### Operational Benchmarking

- The overall Delivered-order benchmarks are 17.34 minutes for kitchen preparation and 4.83 minutes for rider wait.
- Aura Pizzas outlet 21077127 has the fastest kitchen average among its brand's outlets at 15.16 minutes, 1.93 minutes faster than the weighted Aura Pizzas benchmark.
- Swaad outlet 20320607 averages 15.86 kitchen minutes, 1.93 minutes faster than the weighted Swaad benchmark.
- Aura Pizzas outlet 21173951 has the shortest average rider wait among outlets with a substantial sample: 3.15 minutes across 916 measured Delivered orders.
- One outlet is faster than the overall benchmark on both kitchen preparation and rider wait, while ten are slower on both measures.

Operational rankings must be considered with measured-order counts. Several smaller outlets have very few observations and should not be treated as equally reliable comparisons.

## Analytics Views

| View | Grain | Purpose |
|---|---|---|
| `vw_executive_kpis` | One row for the current dataset | Supplies headline order, customer, delivery-success, and Delivered-value KPIs. |
| `vw_monthly_performance` | One row per calendar month | Supplies monthly orders, prior-month comparisons, growth rates, and cumulative Delivered value. |
| `vw_restaurant_performance` | One row per restaurant outlet | Supplies outlet demand, delivery success, Delivered value, average order value, kitchen time, and rider wait. |
| `vw_customer_segments` | One row per anonymized customer | Supplies order counts, Delivered value, frequency segment, value quartile, and high-value flag. |
| `vw_operational_performance` | One row per restaurant outlet | Supplies outlet, brand, and overall time benchmarks plus rider-wait ranking and performance labels. |

Validated view row counts:

| View | Rows |
|---|---:|
| `vw_executive_kpis` | 1 |
| `vw_monthly_performance` | 5 |
| `vw_restaurant_performance` | 21 |
| `vw_customer_segments` | 11,607 |
| `vw_operational_performance` | 21 |

These views centralize metric definitions so future Power BI measures do not need to recreate core SQL logic.

## Limitations and Assumptions

- The analysis covers five months, which is insufficient to establish long-term seasonality.
- Month-over-month comparisons do not adjust for calendar length, holidays, outlet launches, or operating hours.
- The seven-day moving average uses the current day and six preceding days. The first six results use partial windows.
- Restaurant rank does not control for capacity, operating hours, outlet age, geography, or product mix.
- Delivered order value is not audited revenue, payout, margin, or profit, and source currency is not explicitly documented.
- `NTILE(4)` creates similarly sized groups, not fixed monetary bands. Quartile thresholds will change when the customer population changes.
- Equal delivered-order values can be divided across adjacent quartiles at a boundary.
- Customer identifiers are anonymized and analysis is limited to activity observed in this dataset.
- Operational averages can hide outliers and do not establish causation. Small outlet samples require particular caution.
- Faster kitchen or rider wait performance measures time only and does not imply better food quality or order accuracy.

## Validation

The complete script was validated with:

```text
psql -d food_delivery_analytics -f sql/05_advanced_sql.sql
```

All analytical queries completed, all five views were created, and the view-grain validation returned the expected row counts.
