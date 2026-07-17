# Power BI Dashboard Implementation Plan

## Purpose

This document defines the implementation plan for a four-page Power BI dashboard built from the existing PostgreSQL analytics views:

- `vw_executive_kpis`
- `vw_monthly_performance`
- `vw_restaurant_performance`
- `vw_customer_segments`
- `vw_operational_performance`

The dashboard should present validated business metrics without recreating SQL transformations unnecessarily. PostgreSQL remains the authoritative semantic layer for fixed KPIs, customer segments, monthly growth, cumulative value, and operational benchmarks.

No SQL table or view changes are required for this plan.

## Dashboard Implementation Progress

| Page | Status |
|---|---|
| Page 1: Executive Overview | Completed |
| Page 2: Restaurant Performance | Completed |
| Page 3: Customer Analysis | In progress |
| Page 4: Operational Performance | In progress |

## Source View Inventory

| View | Grain | Primary identifier | Intended use |
|---|---|---|---|
| `vw_executive_kpis` | One row for the complete dataset | None required | All-time executive KPI cards |
| `vw_monthly_performance` | One row per calendar month | `order_month` | Monthly trends and growth |
| `vw_restaurant_performance` | One row per restaurant outlet | `restaurant_id` | Outlet and brand performance |
| `vw_customer_segments` | One row per anonymized customer | `customer_id` | Frequency, value, and high-value segmentation |
| `vw_operational_performance` | One row per restaurant outlet | `restaurant_id` | Kitchen and rider-wait benchmarking |

## Recommended Connection Mode

Use PostgreSQL as the source and import the five views into Power BI.

Import mode is recommended because the dataset is small, the views are already aggregated, and interactive filtering will be faster than repeatedly querying PostgreSQL. Configure credentials and refresh in the Power BI Service only when publishing begins.

Recommended Power Query steps should remain minimal:

- Confirm numeric and date data types.
- Rename fields only for display; preserve source column names internally where practical.
- Create the small restaurant and month dimensions described below.
- Do not recreate customer segments, monthly growth, cumulative value, or operational benchmark logic.

## Data Model

### Recommended Tables

Use the five imported views plus two small dimension tables created as Power Query references:

#### `dim_restaurant`

Create from `vw_restaurant_performance` by selecting and deduplicating:

- `restaurant_id`
- `restaurant_name`

Expected grain: one row per restaurant outlet.

#### `dim_month`

Create from `vw_monthly_performance` by selecting:

- `order_month`

Add presentation-only columns in Power Query:

- `month_label`, formatted as `MMM yyyy`
- `month_sort`, formatted as `yyyyMM`

Sort `month_label` by `month_sort`.

### Supported Relationships

| From | To | Cardinality | Filter direction | Justification |
|---|---|---|---|---|
| `dim_restaurant[restaurant_id]` | `vw_restaurant_performance[restaurant_id]` | One-to-one at the current grain | Single direction from dimension | Both tables contain one row per documented outlet. |
| `dim_restaurant[restaurant_id]` | `vw_operational_performance[restaurant_id]` | One-to-one at the current grain | Single direction from dimension | Both analytics views use the same outlet identifier and grain. |
| `dim_month[order_month]` | `vw_monthly_performance[order_month]` | One-to-one at the current grain | Single direction from dimension | Both contain one row per observed month. |

Power BI may display these as one-to-one relationships because the analytics views are already aggregated. Keep single-direction filters from the dimension tables so the model behaves like a simple star schema and avoids ambiguous paths.

### Intentionally Disconnected Tables

- `vw_executive_kpis` must remain disconnected because it is a one-row, all-time aggregate with no month, outlet, or customer key.
- `vw_customer_segments` must remain disconnected because it contains customer-level aggregates without month or outlet keys.
- `vw_monthly_performance` must not be related to restaurant, customer, or operational views because those views do not contain `order_month`.

### Data-Model Risks

- A month slicer can filter only `vw_monthly_performance`. It cannot recalculate the all-time executive KPIs or filter outlet/customer views.
- A restaurant slicer can filter restaurant and operational visuals through `dim_restaurant`, but not monthly, customer, or executive data.
- Customer segments cannot be analyzed by month, restaurant, or brand using the current view grain.
- Creating unsupported many-to-many or cross-filter relationships would produce misleading totals and should be avoided.
- Combining all views into one table would repeat aggregates at incompatible grains and cause double-counting.
- `vw_executive_kpis` should always be presented as “All-time” or with the dataset date range visible.

## Required Power BI Measures

The measures below either expose PostgreSQL-provided values safely or perform necessary filter-context aggregation. They do not rebuild customer segmentation, SQL rankings, monthly growth, cumulative totals, or benchmark definitions.

Create a dedicated `_Measures` table to hold all DAX measures.

### Executive Measures

These use `MAX` because `vw_executive_kpis` contains exactly one row.

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

Format the success-rate measure as a percentage. Dividing the stored percentage by 100 is a display conversion, not a recalculation of the underlying business metric.

### Monthly Measures

```DAX
Monthly Total Orders =
SUM ( vw_monthly_performance[total_orders] )

Monthly Delivered Orders =
SUM ( vw_monthly_performance[delivered_orders] )

Monthly Delivered Order Value =
SUM ( vw_monthly_performance[delivered_order_value] )

Monthly Order Growth =
SELECTEDVALUE (
    vw_monthly_performance[month_over_month_order_growth_pct]
) / 100

Monthly Delivered Value Growth =
SELECTEDVALUE (
    vw_monthly_performance[month_over_month_delivered_value_growth_pct]
) / 100

Cumulative Delivered Order Value =
MAX ( vw_monthly_performance[cumulative_delivered_order_value] )
```

The growth measures should be used only when the visual context contains one month. They should remain blank for the first month or when multiple months are selected.

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

The two ratio measures are required for correct weighted results when multiple outlets or an entire brand are selected. Averaging the outlet-level rate or average-value columns would be incorrect.

### Customer Measures

```DAX
Customer Count =
COUNTROWS ( vw_customer_segments )

Customer Total Orders =
SUM ( vw_customer_segments[total_orders] )

Customer Delivered Orders =
SUM ( vw_customer_segments[delivered_orders] )

Customer Delivered Order Value =
SUM ( vw_customer_segments[delivered_order_value] )

Average Delivered Value per Customer =
DIVIDE (
    [Customer Delivered Order Value],
    [Customer Count]
)

High-Value Customer Count =
CALCULATE (
    [Customer Count],
    vw_customer_segments[is_high_value_customer] = TRUE ()
)

High-Value Customer Share =
DIVIDE (
    [High-Value Customer Count],
    CALCULATE (
        [Customer Count],
        REMOVEFILTERS (
            vw_customer_segments[is_high_value_customer]
        )
    )
)

High-Value Delivered Value =
CALCULATE (
    [Customer Delivered Order Value],
    vw_customer_segments[is_high_value_customer] = TRUE ()
)

High-Value Delivered Value Share =
DIVIDE (
    [High-Value Delivered Value],
    CALCULATE (
        [Customer Delivered Order Value],
        REMOVEFILTERS (
            vw_customer_segments[is_high_value_customer]
        )
    )
)
```

The high-value measures consume the PostgreSQL flag and do not reproduce its 5+ Delivered orders and Q4 logic.

### Operational Measures

```DAX
Weighted Average Kitchen Minutes =
DIVIDE (
    SUMX (
        vw_operational_performance,
        vw_operational_performance[average_kpt_minutes]
            * vw_operational_performance[kpt_measured_orders]
    ),
    SUM ( vw_operational_performance[kpt_measured_orders] )
)

Weighted Average Rider Wait Minutes =
DIVIDE (
    SUMX (
        vw_operational_performance,
        vw_operational_performance[average_rider_wait_minutes]
            * vw_operational_performance[rider_wait_measured_orders]
    ),
    SUM ( vw_operational_performance[rider_wait_measured_orders] )
)

Overall Kitchen Benchmark =
MAX ( vw_operational_performance[overall_average_kpt_minutes] )

Overall Rider Wait Benchmark =
MAX (
    vw_operational_performance[overall_average_rider_wait_minutes]
)

Outlets Faster on Both Measures =
CALCULATE (
    DISTINCTCOUNT ( vw_operational_performance[restaurant_id] ),
    vw_operational_performance[kitchen_benchmark_status] = "Faster",
    vw_operational_performance[rider_wait_benchmark_status] = "Faster"
)
```

The weighted measures are necessary because averaging outlet averages would give small and large outlets equal influence. Minor differences from PostgreSQL may occur because the view exposes rounded outlet averages; use the provided overall benchmark columns for the official all-outlet benchmark cards.

## Page 1: Executive Overview — Completed

**Implementation status:** Completed in `dashboard/Food_Delivery_Analytics_Dashboard.pbix`.

### Business Purpose

Give leadership a concise all-time summary of business scale, delivery success, delivered order value, monthly value trends, restaurant contribution, and customer-frequency composition.

### Implemented Layout

| Visual | Visual type | Source view | Source columns or measure | Business purpose |
|---|---|---|---|---|
| Total Orders | KPI card | `vw_executive_kpis` | `total_orders` / Executive Total Orders | Show total order demand across every final status. |
| Delivered Order Value | KPI card | `vw_executive_kpis` | `delivered_order_value` / Executive Delivered Order Value | Show final order value from Delivered orders only. |
| Delivered Orders | KPI card | `vw_executive_kpis` | `delivered_orders` / Executive Delivered Orders | Show successfully delivered order volume. |
| Delivery Success Rate | KPI card | `vw_executive_kpis` | `delivery_success_rate_pct` / Executive Delivery Success Rate | Show Delivered orders as a share of all orders. |
| Average Delivered Order Value | KPI card | `vw_executive_kpis` | `average_delivered_order_value` / Executive Average Delivered Order Value | Show average final value per Delivered order. |
| Unique Customers | KPI card | `vw_executive_kpis` | `unique_customers` / Executive Unique Customers | Show the observed anonymized customer base. |
| Monthly Delivered Order Value Trend | Trend chart | `vw_monthly_performance` | `order_month`, `delivered_order_value` | Show how delivered order value changes across the five observed months. |
| Top 5 Restaurants by Delivered Order Value | Ranked bar chart | `vw_restaurant_performance` | `restaurant_name`, `delivered_order_value`; Top N = 5 | Identify the five restaurant names contributing the most delivered order value. |
| Customer Frequency Segments | Segment chart | `vw_customer_segments` | `frequency_segment`, count of `customer_id` | Show the customer base split across One-time, Repeat, and Loyal frequency groups. |

### Validated KPI Values

| KPI | Displayed value |
|---|---:|
| Total Orders | 21,321 |
| Delivered Order Value | 14,423,379.76 |
| Delivered Orders | 21,131 |
| Delivery Success Rate | 99.11% |
| Average Delivered Order Value | 682.57 |
| Unique Customers | 11,607 |

All six cards are fixed all-time metrics from the one-row executive view.

### Delivery Success Rate Presentation Measure

PostgreSQL supplies `delivery_success_rate_pct` as `99.11`. The implemented Power BI presentation measure divides that SQL percentage value by 100 so Power BI can format the result correctly as `99.11%`:

```DAX
Executive Delivery Success Rate =
MAX ( vw_executive_kpis[delivery_success_rate_pct] ) / 100
```

This is a presentation conversion only. It does not redefine or recalculate the SQL business metric.

### Customer Frequency Categories

The Customer Frequency Segments visual uses the categories already assigned by `vw_customer_segments`:

- **One-time:** exactly 1 order.
- **Repeat:** 2–4 orders.
- **Loyal:** 5 or more orders.

Frequency counts use all order attempts, regardless of final status, consistent with the PostgreSQL view definition.

### Filter and Interaction Scope

- The six executive KPI cards are all-time values from the disconnected, one-row `vw_executive_kpis` view.
- The monthly trend is scoped to `vw_monthly_performance`.
- The Top 5 restaurant visual is scoped to `vw_restaurant_performance`.
- The customer-frequency visual is scoped to `vw_customer_segments`.
- These views have different grains and are intentionally disconnected except where a supported dimension is explicitly documented elsewhere in this plan.
- Page 1 must not imply that selecting a month, restaurant, or customer segment recalculates the disconnected executive KPIs or filters the other disconnected subject areas.
- No unsupported cross-view slicer behavior is claimed for the completed page.

### Business Interpretation

- The KPI row establishes overall business scale and delivery performance.
- The monthly trend adds time context for delivered order value without changing the all-time cards.
- The Top 5 restaurant chart shows where delivered order value is concentrated.
- The frequency-segment chart adds a customer-retention perspective using One-time, Repeat, and Loyal categories.

### Tooltips

- Monthly trend tooltip: month and delivered order value.
- Top 5 restaurant tooltip: restaurant name and delivered order value.
- Customer-frequency tooltip: frequency segment and customer count.
- Tooltip wording should preserve the term **delivered order value** and should not relabel it as an accounting metric.

## Page 2: Restaurant Performance — Completed

**Implementation status:** Completed in `dashboard/Food_Delivery_Analytics_Dashboard.pbix`.

### Business Purpose

Compare restaurant brands and outlets on demand, successful fulfillment, delivered order value, and average order value. The page should help identify high-contribution outlets and separate scale from value mix.

### Implementation Progress

- ✓ Restaurant list slicer completed
- ✓ KPI cards implemented
- ✓ Restaurant performance matrix implemented
- ✓ Top Restaurant Brands by Delivered Order Value chart completed
- ✓ Order Volume vs Average Order Value scatter chart completed
- ✓ Visual formatting completed
- ✓ Interactive filtering validated

### Implemented Layout

| Visual | Visual type | Source | Business purpose |
|---|---|---|---|
| Restaurant list | Slicer | `dim_restaurant[restaurant_name]` | Filter Page 2 to the selected restaurant brand or brands. |
| Total Orders | KPI card | Restaurant Total Orders | Show all order attempts in the current restaurant filter context. |
| Delivered Order Value | KPI card | Restaurant Delivered Order Value | Show final order value from Delivered orders in the current filter context. |
| Delivery Success Rate | KPI card | Restaurant Delivery Success Rate | Show Delivered orders as a share of all orders in the current filter context. |
| Average Order Value | KPI card | Restaurant Average Delivered Order Value | Show average final value per Delivered order in the current filter context. |
| Top Restaurant Brands by Delivered Order Value | Horizontal bar chart | `restaurant_name`, Restaurant Delivered Order Value | Rank restaurant brands by delivered order value. |
| Order Volume vs Average Order Value | Scatter chart | Restaurant Total Orders, Restaurant Average Delivered Order Value, Restaurant Delivered Order Value, `restaurant_name` | Compare restaurant demand, average delivered order value, and overall value contribution. |
| Restaurant Performance Detail | Matrix | `restaurant_name` with restaurant and operational performance fields | Provide detailed restaurant-level metrics for comparison and review. |

### KPIs

- Restaurant Total Orders
- Restaurant Delivered Order Value
- Restaurant Delivery Success Rate
- Restaurant Average Delivered Order Value

### Filters and Slicers

- Restaurant list: `dim_restaurant[restaurant_name]`
- The restaurant selection filters the KPI cards, bar chart, scatter chart, and detail matrix.

Do not add a month slicer because this view contains all-time outlet aggregates.

### Validated Interactions

- Restaurant-list selections filter every visual on Page 2.
- Bar-chart and scatter-chart selections support comparative filtering and highlighting.
- The detail matrix responds to the active restaurant filter context.
- Page 2 remains an all-time restaurant analysis and does not claim unsupported month filtering.

### Tooltips

Use a shared outlet tooltip page containing:

- Restaurant brand and outlet ID
- Total and Delivered orders
- Delivery success rate
- Delivered order value
- Average delivered order value
- Average kitchen preparation time
- Average rider wait time

The restaurant data can retrieve both restaurant and operational view metrics where the supported restaurant identifier relationship is present.

## Page 3: Customer Analysis

### Business Purpose

Explain customer composition, ordering frequency, delivered-value concentration, and the size and contribution of the defined high-value segment.

### Recommended Layout

| Area | Visual | Content | Source columns |
|---|---|---|---|
| Header | Title and segmentation note | Frequency and Q1–Q4 definitions | Static text |
| Top row | Four KPI cards | Customer count, customer delivered order value, high-value customer count, high-value delivered-value share | Customer measures |
| Middle left | Horizontal bar chart | Customers by frequency segment | `frequency_segment`, Customer Count |
| Middle center | Column chart | Delivered order value by value segment | `value_segment`, Customer Delivered Order Value |
| Middle right | 100% stacked bar chart | Frequency-segment mix within each value quartile | `value_segment`, `frequency_segment`, Customer Count |
| Bottom left | Scatter chart | X: total orders; Y: delivered order value; color: frequency segment; high-value flag as shape/filter | `total_orders`, `delivered_order_value`, `frequency_segment`, `is_high_value_customer`, `customer_id` |
| Bottom right | Detail table | Anonymized customer, total orders, Delivered orders, delivered value, frequency segment, value segment, high-value flag | `vw_customer_segments` |

For scatter-chart performance, apply a reasonable visual-level filter, such as high-value customers only, or use aggregation/binning rather than plotting all 11,607 customers simultaneously.

### KPIs

- Customer Count
- Customer Delivered Order Value
- High-Value Customer Count
- High-Value Delivered Value Share

Optional secondary cards:

- Customer Total Orders
- Average Delivered Value per Customer
- High-Value Customer Share

### Filters and Slicers

- Frequency segment: `frequency_segment`
- Value segment: `value_segment`
- High-value status: `is_high_value_customer`
- Delivered-order count range
- Delivered-order-value range

Sort `value_segment` by `value_quartile`, not alphabetically.

Do not add month, brand, or outlet slicers because those keys do not exist in the customer view.

### Recommended Interactions

- Frequency and value segment charts should cross-filter each other and the detail table.
- Selecting Q4 should reveal its composition across One-time, Repeat, and Loyal frequency segments.
- Selecting the high-value KPI or a dedicated button should filter the detail table to `is_high_value_customer = TRUE`.
- Provide a reset-filters bookmark because customer filters can combine into narrow populations.

### Tooltips

- Segment tooltip: customer count, customer share, total orders, Delivered orders, delivered order value, and average value per customer.
- Customer tooltip: anonymized ID, frequency segment, value quartile, total orders, Delivered orders, delivered order value, and high-value status.

Do not expose or imply personally identifiable information; `customer_id` is anonymized.

## Page 4: Operational Performance

### Business Purpose

Benchmark outlets on kitchen preparation and rider wait time, identify faster/slower performance relative to overall benchmarks, and prioritize operational investigation while preserving sample-size context.

### Recommended Layout

| Area | Visual | Content | Source columns |
|---|---|---|---|
| Header | Title and benchmark note | “Delivered orders only · Lower duration is faster” | Static text |
| Top row | Four KPI cards | Overall kitchen benchmark, overall rider-wait benchmark, selected weighted kitchen average, selected weighted rider-wait average | Operational measures |
| Middle left | Quadrant scatter chart | X: average kitchen minutes; Y: average rider wait; bubble size: Delivered orders; detail: outlet; color: brand | `average_kpt_minutes`, `average_rider_wait_minutes`, `delivered_orders`, `restaurant_id`, `restaurant_name` |
| Middle right | Ranked horizontal bar chart | Average rider wait by outlet, sorted ascending; show rider-wait rank | `restaurant_id`, `restaurant_name`, `average_rider_wait_minutes`, `rider_wait_performance_rank` |
| Bottom | Matrix | Brand → outlet with measured-order counts, outlet averages, brand kitchen average, overall averages, status labels, and wait rank | `vw_operational_performance` |

Add constant/reference lines to the scatter chart at the official overall benchmark values. This creates four operational quadrants without inventing a composite score.

### KPIs

- Overall Kitchen Benchmark
- Overall Rider Wait Benchmark
- Weighted Average Kitchen Minutes
- Weighted Average Rider Wait Minutes
- Optional: Outlets Faster on Both Measures

### Filters and Slicers

- Brand and outlet from `dim_restaurant`
- Kitchen benchmark status
- Rider-wait benchmark status
- Minimum measured-order threshold

Default the minimum sample-size filter to a clearly displayed threshold only if the business owner approves one. Until then, show all outlets and make measured-order counts prominent rather than silently excluding small samples.

Do not add a month slicer because the operational view contains all-time outlet aggregates.

### Recommended Interactions

- Brand selection filters the scatter, bar, matrix, and selected weighted-average cards.
- Selecting an outlet cross-highlights all operational visuals.
- Benchmark cards remain official all-outlet values and should not change with outlet selection; selected weighted-average cards should respond to filters.
- Provide a button to drill through to Outlet Detail.

### Tooltips

Operational outlet tooltip:

- Outlet ID and brand
- Delivered orders
- Kitchen measured orders
- Average kitchen minutes
- Brand and overall kitchen benchmarks
- Kitchen benchmark status
- Rider-wait measured orders
- Average rider-wait minutes
- Overall rider-wait benchmark
- Rider-wait status and rank

Always include measured-order counts to prevent overinterpretation of small samples.

## Drill-Through Opportunities

### Outlet Detail Drill-Through

Create one hidden drill-through page filtered by `dim_restaurant[restaurant_id]`.

Recommended content:

- Restaurant performance KPIs
- Operational performance KPIs
- Comparison of outlet kitchen time with brand and overall benchmarks
- Comparison of outlet rider wait with the overall benchmark
- Outlet rank and measured-order counts
- Back button to the originating page

This drill-through is supported because both outlet views share the documented `restaurant_id` grain through `dim_restaurant`.

### Customer Detail Drill-Through

An optional hidden page may use `vw_customer_segments[customer_id]` to display the selected customer's aggregated segment record. It cannot show order history, restaurant preference, or monthly activity because those fields are not present in the customer view.

### Month Detail

A separate drill-through page is unnecessary with only five monthly rows. A rich report-page tooltip provides the same information more efficiently.

## Dashboard Layout Guidance

- Use a 16:9 canvas, preferably 1280 × 720 or the standard Power BI widescreen page size.
- Use a consistent grid with approximately 24-pixel outer margins and 12–16-pixel spacing between visuals.
- Reserve the top 10–12% for the page title, scope subtitle, navigation, and reset-filters control.
- Keep KPI cards in one aligned row and use consistent dimensions across pages.
- Place primary analytical visuals in the middle and detailed matrices at the bottom.
- Limit each page to the visuals needed for its business question; avoid decorative charts.
- Keep slicers in a consistent left rail or top strip across pages.
- Use a visible filter-summary label so users understand the active brand, outlet, or customer segment.

## Formatting Recommendations

### Theme

Use a restrained theme with:

- Dark navy or charcoal for titles and primary text.
- One primary accent color for order volume.
- A second accent color for delivered order value.
- Green for Faster/positive status and muted red or amber for Slower/negative status.
- Neutral gray for benchmarks and comparison lines.
- White or very light gray canvas background.

Do not rely on red and green alone; pair color with labels, icons, or patterns.

### Number Formats

- Orders and customers: whole numbers with thousands separators.
- Delivered order value: thousands separators and zero or two decimals depending on available space. Do not add a currency symbol until the source currency is confirmed.
- Average order value: two decimals.
- Percentages: one or two decimals with `%`.
- Durations: two decimals with `min` in the visual title or label.
- Dates: `MMM yyyy` for monthly visuals.

Use the phrase **delivered order value** everywhere. Do not present it as an accounting metric.

### Titles and Labels

- Use question-based visual titles where possible, such as “Which outlets contribute the most delivered order value?”
- Use dynamic subtitles for active filter context.
- Prefer direct labels on short ranked charts and legends only when necessary.
- Keep brand colors consistent across all pages if brand-specific colors are used.

## Tooltip Standards

- Use report-page tooltips for month, outlet, and customer-segment contexts.
- Include both the primary metric and its denominator or sample size.
- Show all-time or selected-context scope explicitly.
- Include operational benchmark definitions in tooltip text.
- Avoid tooltips that merely repeat a data label without adding context.

## Accessibility

- Meet at least WCAG AA contrast for text and meaningful visual elements.
- Do not communicate status using color alone; include “Faster,” “Slower,” or icons with accessible labels.
- Set descriptive alt text for every visual, including its business meaning and filter behavior.
- Configure keyboard tab order from page title and slicers through KPIs, charts, detail tables, and navigation.
- Use a minimum readable font size of approximately 11–12 points for labels and 14 points for key supporting text.
- Avoid rotated axis labels and excessive abbreviations.
- Provide data tables or “Show as a table” support for chart users who need exact values.
- Ensure tooltip content is concise and does not contain essential information unavailable elsewhere.
- Test the report using Power BI accessibility checks and a color-vision-deficiency simulator.

## Interaction and Navigation Standards

- Use the same four page-navigation buttons in the same location on every page.
- Add a reset-filters bookmark on Restaurant, Customer, and Operational pages.
- Configure visual interactions deliberately; do not accept all default cross-highlighting.
- Prevent all-time KPI cards from appearing to respond to unsupported month or outlet filters.
- Synchronize only slicers that are supported across the relevant pages. The brand/outlet slicer may be synchronized between Restaurant and Operational pages; customer and month slicers should remain page-specific.
- Keep drill-through filters visible on detail pages and provide a clear back button.

## Recommended Build Sequence

1. Connect to PostgreSQL and import the five analytics views.
2. Validate row counts against the Advanced SQL report.
3. Confirm data types and create `dim_restaurant` and `dim_month` as Power Query references.
4. Create only the supported relationships with single-direction filtering.
5. Create the `_Measures` table and DAX measures in this plan.
6. Apply the report theme, number formats, and sort columns.
7. Build Executive Overview and validate all-time versus monthly filter behavior.
8. Build Restaurant and Operational pages together because they share `dim_restaurant`.
9. Build Customer Analysis as a disconnected subject area.
10. Add tooltip and outlet drill-through pages.
11. Configure interactions, navigation, alt text, and keyboard tab order.
12. Reconcile KPI and view totals with PostgreSQL before publishing.

## Validation Checklist

- Executive cards match `vw_executive_kpis` exactly.
- Monthly rows, growth rates, and cumulative values match `vw_monthly_performance`.
- Restaurant totals reconcile when summing all 21 outlets.
- Customer segment counts sum to 11,607 customers.
- Value quartiles sort Q1 through Q4 and use the PostgreSQL-provided labels.
- High-value customer measures use `is_high_value_customer` rather than rebuilding the flag.
- Operational benchmark cards use the PostgreSQL-provided overall benchmark fields.
- Restaurant and operational pages filter consistently by `restaurant_id`.
- Month filters do not alter all-time executive, restaurant, customer, or operational visuals.
- No view is joined at an unsupported grain.
- Every visual uses the term delivered order value and avoids accounting terminology.
- Small operational samples display their measured-order counts.
- Power BI remains a presentation and interaction layer over the validated PostgreSQL logic.
