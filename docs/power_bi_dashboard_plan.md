# Power BI Dashboard Implementation Plan

## Purpose and Final Scope

This document records the finalized implementation of a two-page Power BI dashboard built from the existing PostgreSQL analytics views:

- `vw_executive_kpis`
- `vw_monthly_performance`
- `vw_restaurant_performance`
- `vw_customer_segments`
- `vw_operational_performance`

The completed dashboard contains:

1. Page 1: Executive Overview
2. Page 2: Restaurant Performance

Standalone Customer Analysis and Operational Performance dashboard pages are not part of the final scope. Those subject areas remain covered by the business-analysis and advanced-SQL workflows, the reusable customer and operational views, and the customer-spending statistical analysis. Their removal is a deliberate scope decision, not an incomplete dashboard milestone.

PostgreSQL remains the authoritative semantic layer. Power BI provides visualization, interaction, and limited presentation measures without recreating SQL transformations unnecessarily. No SQL table or view changes are required for this dashboard.

## Dashboard Implementation Progress

| Page | Status |
|---|---|
| Page 1: Executive Overview | Completed |
| Page 2: Restaurant Performance | Completed |
| Overall two-page dashboard | Completed |

The implemented report is stored at `dashboard/Food_Delivery_Analytics_Dashboard.pbix`.

## Source View Inventory

| View | Grain | Primary identifier | Role in the project |
|---|---|---|---|
| `vw_executive_kpis` | One row for the complete dataset | None required | Page 1 all-time KPI cards |
| `vw_monthly_performance` | One row per calendar month | `order_month` | Page 1 monthly trend |
| `vw_restaurant_performance` | One row per restaurant outlet | `restaurant_id` | Page 1 restaurant ranking and Page 2 restaurant analysis |
| `vw_customer_segments` | One row per anonymized customer | `customer_id` | Page 1 frequency-segment visual and reusable customer analysis |
| `vw_operational_performance` | One row per restaurant outlet | `restaurant_id` | Reusable SQL operational analysis and supported Page 2 detail context |

The source views have different grains. They must not be combined through unsupported relationships or assumed to cross-filter one another.

## Connection and Data Model

Import mode is appropriate because the dataset is small and the analytics views are already aggregated. Power Query transformations should remain limited to data types, display labels, and supported dimensions.

### Supported Restaurant Dimension

`dim_restaurant` can be created from `vw_restaurant_performance` by selecting and deduplicating:

- `restaurant_id`
- `restaurant_name`

The supported relationships are single-direction filters from `dim_restaurant[restaurant_id]` to the same key in:

- `vw_restaurant_performance`
- `vw_operational_performance`

Both views use the documented restaurant-outlet grain. No relationship is supported from the restaurant dimension to the executive, monthly, or customer views.

### Disconnected Views

- `vw_executive_kpis` remains disconnected because it is a one-row all-time aggregate.
- `vw_monthly_performance` has no supported key to the restaurant, customer, or operational views.
- `vw_customer_segments` has no month or restaurant key and remains disconnected.

### Data-Model Risks

- A restaurant selection can filter only visuals connected through the supported restaurant key.
- Page 1 visuals use multiple grains and must not imply unsupported cross-filtering.
- The all-time executive cards do not recalculate for restaurant, month, or customer-segment selections.
- Joining aggregate views at incompatible grains would duplicate values and produce misleading totals.

## Power BI Measures

The report uses PostgreSQL-provided metrics wherever possible. DAX is limited to safe aggregation, weighted ratios in the active restaurant context, and percentage presentation.

### Executive Measures

```DAX
Executive Total Orders =
MAX ( vw_executive_kpis[total_orders] )

Executive Delivered Orders =
MAX ( vw_executive_kpis[delivered_orders] )

Executive Unique Customers =
MAX ( vw_executive_kpis[unique_customers] )

Executive Delivery Success Rate =
MAX ( vw_executive_kpis[delivery_success_rate_pct] ) / 100

Executive Delivered Order Value =
MAX ( vw_executive_kpis[delivered_order_value] )

Executive Average Delivered Order Value =
MAX ( vw_executive_kpis[average_delivered_order_value] )
```

The SQL success-rate value is stored as `99.11`. Dividing by 100 is a presentation conversion that allows Power BI to display `99.11%`; it does not redefine the metric.

### Restaurant Measures

```DAX
Restaurant Total Orders =
SUM ( vw_restaurant_performance[total_orders] )

Restaurant Delivered Orders =
SUM ( vw_restaurant_performance[delivered_orders] )

Restaurant Delivered Order Value =
SUM ( vw_restaurant_performance[delivered_order_value] )

Restaurant Delivery Success Rate =
DIVIDE (
    [Restaurant Delivered Orders],
    [Restaurant Total Orders]
)

Restaurant Average Delivered Order Value =
DIVIDE (
    [Restaurant Delivered Order Value],
    [Restaurant Delivered Orders]
)
```

The two ratio measures calculate weighted results in the active restaurant context. Averaging outlet-level rates or outlet-level average values would be incorrect.

## Page 1: Executive Overview — Completed

**Implementation status:** Completed in `dashboard/Food_Delivery_Analytics_Dashboard.pbix`.

### Business Purpose

Give leadership a concise all-time summary of business scale, delivery success, delivered order value, monthly value trends, restaurant contribution, and customer-frequency composition.

### Implemented Layout

| Visual | Visual type | Source view | Source column or measure | Business purpose |
|---|---|---|---|---|
| Total Orders | KPI card | `vw_executive_kpis` | Executive Total Orders | Show order demand across all final statuses. |
| Delivered Order Value | KPI card | `vw_executive_kpis` | Executive Delivered Order Value | Show final order value from Delivered orders only. |
| Delivered Orders | KPI card | `vw_executive_kpis` | Executive Delivered Orders | Show successfully delivered order volume. |
| Delivery Success Rate | KPI card | `vw_executive_kpis` | Executive Delivery Success Rate | Show Delivered orders as a share of all orders. |
| Average Delivered Order Value | KPI card | `vw_executive_kpis` | Executive Average Delivered Order Value | Show average final value per Delivered order. |
| Unique Customers | KPI card | `vw_executive_kpis` | Executive Unique Customers | Show the observed anonymized customer base. |
| Monthly Delivered Order Value Trend | Trend chart | `vw_monthly_performance` | `order_month`, `delivered_order_value` | Show delivered order value across the five observed months. |
| Top 5 Restaurants by Delivered Order Value | Ranked bar chart | `vw_restaurant_performance` | `restaurant_name`, `delivered_order_value` | Identify the five brands contributing the most delivered order value. |
| Customer Frequency Segments | Segment chart | `vw_customer_segments` | `frequency_segment`, count of `customer_id` | Show customer composition by ordering frequency. |

### Validated KPI Values

| KPI | Value |
|---|---:|
| Total Orders | 21,321 |
| Delivered Orders | 21,131 |
| Delivery Success Rate | 99.11% |
| Delivered Order Value | 14,423,379.76 |
| Average Delivered Order Value | 682.57 |
| Unique Customers | 11,607 |

The screenshot uses abbreviated card formatting for large values; the table above records the exact validated values.

### Customer Frequency Categories

- **One-time:** exactly 1 order
- **Repeat:** 2–4 orders
- **Loyal:** 5 or more orders

Frequency counts use all order attempts, regardless of final status, consistent with the PostgreSQL view definition.

### Filter and Interaction Scope

- Executive KPI cards are fixed all-time values from the disconnected executive view.
- The monthly trend, restaurant ranking, and customer-frequency visual are each scoped to their own source view.
- No unsupported cross-view slicer or selection behavior is claimed.

## Page 2: Restaurant Performance — Completed

**Implementation status:** Completed in `dashboard/Food_Delivery_Analytics_Dashboard.pbix`.

### Business Purpose

Compare restaurant brands on order demand, successful fulfillment, delivered order value, and average delivered order value. The page separates scale from order-value mix and supports interactive restaurant filtering.

### Implementation Progress

- ✓ Restaurant list slicer completed
- ✓ KPI cards implemented
- ✓ Restaurant Performance Detail matrix implemented
- ✓ Top Restaurant Brands by Delivered Order Value chart completed
- ✓ Order Volume vs Average Order Value scatter chart completed
- ✓ Visual formatting completed
- ✓ Interactive filtering validated

### Implemented Layout

| Visual | Visual type | Source | Business purpose |
|---|---|---|---|
| Restaurant list | Slicer | `dim_restaurant[restaurant_name]` | Filter Page 2 to selected restaurant brands. |
| Total Orders | KPI card | Restaurant Total Orders | Show all order attempts in the current restaurant context. |
| Delivered Order Value | KPI card | Restaurant Delivered Order Value | Show final value from Delivered orders in the current context. |
| Delivery Success Rate | KPI card | Restaurant Delivery Success Rate | Show Delivered orders as a share of all orders. |
| Average Order Value | KPI card | Restaurant Average Delivered Order Value | Show average final value per Delivered order. |
| Top Restaurant Brands by Delivered Order Value | Horizontal bar chart | `restaurant_name`, Restaurant Delivered Order Value | Rank restaurant brands by delivered order value. |
| Order Volume vs Average Order Value | Scatter chart | Restaurant Total Orders, Restaurant Average Delivered Order Value, `restaurant_name` | Compare restaurant demand and average delivered order value. |
| Restaurant Performance Detail | Matrix | Restaurant performance fields | Provide detailed restaurant-level comparison and totals. |

### Filters and Interactions

- The restaurant list filters the KPI cards, bar chart, scatter chart, and detail matrix.
- Bar-chart and scatter-chart selections support comparative filtering and highlighting.
- The matrix responds to the active restaurant context.
- Page 2 is an all-time analysis and does not claim unsupported month filtering.

### Validated All-Restaurant Totals

| Metric | Value |
|---|---:|
| Total Orders | 21,321 |
| Delivered Orders | 21,131 |
| Delivery Success Rate | 99.11% |
| Delivered Order Value | 14,423,379.76 |
| Average Delivered Order Value | 682.57 |

## Analytical Coverage Outside the Dashboard

The two-page dashboard does not remove customer or operational analysis from the project:

- Customer composition, frequency, value quartiles, and contribution are available in `vw_customer_segments`, `sql/05_advanced_sql.sql`, and `docs/advanced_sql_report.md`.
- Customer spending differences are tested in `python/customer_hypothesis_testing.py` and documented in `docs/customer_spending_analysis.md`.
- Operational preparation and rider-wait benchmarks are available in `vw_operational_performance`, `sql/04_business_analysis.sql`, `sql/05_advanced_sql.sql`, and their reports.

No additional Power BI pages are required for the finalized project scope.

## Formatting and Accessibility Standards

- Use a 16:9 canvas with consistent spacing and aligned KPI cards.
- Format orders and customers as whole numbers with thousands separators.
- Format delivered order value with thousands separators; avoid accounting claims.
- Format rates as percentages and average delivered order value to two decimals.
- Use **delivered order value**, not revenue or profit, in documentation and future visual revisions.
- Maintain readable labels, WCAG AA contrast, descriptive alt text, and a logical keyboard tab order.
- Do not communicate status by color alone.
- Keep titles, slicers, and navigation consistent across both pages.

## Final Validation Checklist

- [x] Page 1 and Page 2 screenshots exist in `images/dashboard/`.
- [x] Executive totals are consistent across the README, analytics reports, and Page 2 matrix.
- [x] Restaurant totals reconcile to 21,321 total orders and 21,131 Delivered orders.
- [x] Delivered order value reconciles to 14,423,379.76.
- [x] Delivery success rate reconciles to 99.11%.
- [x] Unique customers reconcile to 11,607.
- [x] Page 1 documentation does not claim unsupported cross-filtering.
- [x] Page 2 uses the supported restaurant filter context.
- [x] Customer and operational analysis remain preserved outside dedicated dashboard pages.
- [x] No additional dashboard pages remain in the required scope.

The finalized screenshots consistently use **delivered order value** for the Page 1 financial metric and preserve the validated underlying calculations.
