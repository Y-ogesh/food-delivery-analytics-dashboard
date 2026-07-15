-- ==================================================
-- 05 Advanced SQL and Analytics Views
-- ==================================================
-- Project: Food Delivery Analytics Dashboard
-- Source: clean_orders only
-- Geography: Delhi NCR
-- Purpose: Demonstrate reusable advanced PostgreSQL analysis patterns
-- and create a semantic view layer for future Power BI consumption.

\pset pager off

-- ==================================================
-- A. Restaurant Rankings
-- ==================================================

-- Business question: How do restaurant outlets rank by delivered order value within each brand?
-- Advanced SQL concept used: Common Table Expression and RANK window function with PARTITION BY.
-- Metric definition: Delivered order value is the sum of total for Delivered orders by outlet;
-- outlets are ranked from highest to lowest value within their restaurant brand.
-- Assumptions: restaurant_id identifies an outlet; ties receive the same rank; total is delivered
-- order value and is not revenue or profit.
WITH outlet_delivered_value AS (
    SELECT
        restaurant_id,
        restaurant_name,
        COUNT(*) AS delivered_orders,
        SUM(total) AS delivered_order_value
    FROM clean_orders
    WHERE order_status = 'Delivered'
    GROUP BY restaurant_id, restaurant_name
)
SELECT
    restaurant_name,
    restaurant_id,
    delivered_orders,
    ROUND(delivered_order_value, 2) AS delivered_order_value,
    RANK() OVER (
        PARTITION BY restaurant_name
        ORDER BY delivered_order_value DESC
    ) AS outlet_value_rank_within_brand
FROM outlet_delivered_value
ORDER BY restaurant_name, outlet_value_rank_within_brand, restaurant_id;

-- Business question: How do brands rank by order demand and delivered order value?
-- Advanced SQL concept used: CTE, conditional aggregation, DENSE_RANK, and percent-of-total windows.
-- Metric definition: Total orders include every status; delivered order value sums total for Delivered
-- orders only; each brand's shares use the corresponding all-brand total.
-- Assumptions: restaurant_name identifies a brand; ties receive the same dense rank; value is not
-- revenue or profit.
WITH brand_performance AS (
    SELECT
        restaurant_name,
        COUNT(*) AS total_orders,
        COUNT(*) FILTER (WHERE order_status = 'Delivered') AS delivered_orders,
        COALESCE(
            SUM(total) FILTER (WHERE order_status = 'Delivered'),
            0
        ) AS delivered_order_value
    FROM clean_orders
    GROUP BY restaurant_name
)
SELECT
    restaurant_name,
    total_orders,
    DENSE_RANK() OVER (ORDER BY total_orders DESC) AS order_volume_rank,
    delivered_orders,
    ROUND(delivered_order_value, 2) AS delivered_order_value,
    DENSE_RANK() OVER (
        ORDER BY delivered_order_value DESC
    ) AS delivered_value_rank,
    ROUND(
        100.0 * total_orders / SUM(total_orders) OVER (),
        2
    ) AS total_order_contribution_pct,
    ROUND(
        100.0 * delivered_order_value
        / NULLIF(SUM(delivered_order_value) OVER (), 0),
        2
    ) AS delivered_value_contribution_pct
FROM brand_performance
ORDER BY order_volume_rank, restaurant_name;

-- ==================================================
-- B. Time-Series Analysis
-- ==================================================

-- Business question: How are monthly order demand and delivered order value changing month over month?
-- Advanced SQL concept used: Layered CTEs and LAG window functions.
-- Metric definition: Order growth compares all order attempts with the prior month; delivered-value
-- growth compares Delivered order value with the prior month.
-- Assumptions: Months are complete calendar months in the source range; the first month has no prior
-- comparison; division by zero returns NULL.
WITH monthly_performance AS (
    SELECT
        DATE_TRUNC('month', order_date)::DATE AS order_month,
        COUNT(*) AS total_orders,
        COUNT(*) FILTER (WHERE order_status = 'Delivered') AS delivered_orders,
        COALESCE(
            SUM(total) FILTER (WHERE order_status = 'Delivered'),
            0
        ) AS delivered_order_value
    FROM clean_orders
    GROUP BY DATE_TRUNC('month', order_date)
), monthly_comparison AS (
    SELECT
        order_month,
        total_orders,
        delivered_orders,
        delivered_order_value,
        LAG(total_orders) OVER (ORDER BY order_month) AS prior_month_orders,
        LAG(delivered_order_value) OVER (
            ORDER BY order_month
        ) AS prior_month_delivered_value
    FROM monthly_performance
)
SELECT
    order_month,
    total_orders,
    prior_month_orders,
    ROUND(
        100.0 * (total_orders - prior_month_orders)
        / NULLIF(prior_month_orders, 0),
        2
    ) AS month_over_month_order_growth_pct,
    delivered_orders,
    ROUND(delivered_order_value, 2) AS delivered_order_value,
    ROUND(prior_month_delivered_value, 2) AS prior_month_delivered_value,
    ROUND(
        100.0 * (delivered_order_value - prior_month_delivered_value)
        / NULLIF(prior_month_delivered_value, 0),
        2
    ) AS month_over_month_delivered_value_growth_pct
FROM monthly_comparison
ORDER BY order_month;

-- Business question: How does delivered order value accumulate across the analysis period?
-- Advanced SQL concept used: CTE and a running-total window frame.
-- Metric definition: Monthly delivered order value is summed cumulatively from the first observed
-- month through the current month.
-- Assumptions: Only Delivered orders contribute value; months are ordered chronologically; delivered
-- order value is not revenue or profit.
WITH monthly_delivered_value AS (
    SELECT
        DATE_TRUNC('month', order_date)::DATE AS order_month,
        SUM(total) AS delivered_order_value
    FROM clean_orders
    WHERE order_status = 'Delivered'
    GROUP BY DATE_TRUNC('month', order_date)
)
SELECT
    order_month,
    ROUND(delivered_order_value, 2) AS delivered_order_value,
    ROUND(
        SUM(delivered_order_value) OVER (
            ORDER BY order_month
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ),
        2
    ) AS cumulative_delivered_order_value
FROM monthly_delivered_value
ORDER BY order_month;

-- Business question: What is the short-term trend in daily order demand after smoothing day-to-day noise?
-- Advanced SQL concept used: CTE and seven-day moving-average window frame.
-- Metric definition: Daily orders include every final status; the moving average uses the current day
-- and six preceding observed calendar days.
-- Assumptions: Every calendar date in the source range has orders; the first six dates use the available
-- partial window and therefore contain fewer than seven days.
WITH daily_order_volume AS (
    SELECT
        order_date,
        COUNT(*) AS total_orders
    FROM clean_orders
    GROUP BY order_date
)
SELECT
    order_date,
    total_orders,
    ROUND(
        AVG(total_orders) OVER (
            ORDER BY order_date
            ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
        ),
        2
    ) AS seven_day_average_orders
FROM daily_order_volume
ORDER BY order_date;

-- ==================================================
-- C. Customer Segmentation
-- ==================================================

-- Business question: How is the customer base distributed across frequency segments?
-- Advanced SQL concept used: CTE, CASE segmentation, and conditional aggregation.
-- Metric definition: One-time customers have 1 total order attempt, Repeat customers have 2-4,
-- and Loyal customers have 5 or more; contribution is the segment's share of all order attempts.
-- Assumptions: Frequency uses every final status, as specified for this milestone; customer_id is stable
-- throughout the analysis period.
WITH customer_frequency AS (
    SELECT
        customer_id,
        COUNT(*) AS total_orders
    FROM clean_orders
    GROUP BY customer_id
), frequency_segments AS (
    SELECT
        customer_id,
        total_orders,
        CASE
            WHEN total_orders = 1 THEN 'One-time'
            WHEN total_orders BETWEEN 2 AND 4 THEN 'Repeat'
            ELSE 'Loyal'
        END AS frequency_segment
    FROM customer_frequency
)
SELECT
    frequency_segment,
    COUNT(*) AS customers,
    SUM(total_orders) AS total_orders,
    ROUND(
        100.0 * COUNT(*) / SUM(COUNT(*)) OVER (),
        2
    ) AS customer_contribution_pct,
    ROUND(
        100.0 * SUM(total_orders) / SUM(SUM(total_orders)) OVER (),
        2
    ) AS order_contribution_pct
FROM frequency_segments
GROUP BY frequency_segment
ORDER BY
    CASE frequency_segment
        WHEN 'One-time' THEN 1
        WHEN 'Repeat' THEN 2
        WHEN 'Loyal' THEN 3
    END;

-- Business question: How is delivered order value distributed across customer value quartiles?
-- Advanced SQL concept used: CTE, NTILE(4), CASE labeling, and percent-of-total window calculation.
-- Metric definition: Customers are assigned Q1 (Lowest) through Q4 (Highest) by their total Delivered
-- order value; each quartile's contribution is its share of all customer delivered order value.
-- Assumptions: Customers with no Delivered orders receive zero value; NTILE creates similarly sized
-- customer groups and can split equal boundary values; value is not revenue or profit.
WITH customer_value AS (
    SELECT
        customer_id,
        COALESCE(
            SUM(total) FILTER (WHERE order_status = 'Delivered'),
            0
        ) AS delivered_order_value
    FROM clean_orders
    GROUP BY customer_id
), value_quartiles AS (
    SELECT
        customer_id,
        delivered_order_value,
        NTILE(4) OVER (
            ORDER BY delivered_order_value, customer_id
        ) AS value_quartile
    FROM customer_value
), labeled_quartiles AS (
    SELECT
        customer_id,
        delivered_order_value,
        value_quartile,
        CASE value_quartile
            WHEN 1 THEN 'Q1 (Lowest)'
            WHEN 2 THEN 'Q2'
            WHEN 3 THEN 'Q3'
            WHEN 4 THEN 'Q4 (Highest)'
        END AS value_segment
    FROM value_quartiles
)
SELECT
    value_quartile,
    value_segment,
    COUNT(*) AS customers,
    ROUND(MIN(delivered_order_value), 2) AS minimum_delivered_order_value,
    ROUND(MAX(delivered_order_value), 2) AS maximum_delivered_order_value,
    ROUND(SUM(delivered_order_value), 2) AS delivered_order_value,
    ROUND(
        100.0 * SUM(delivered_order_value)
        / NULLIF(SUM(SUM(delivered_order_value)) OVER (), 0),
        2
    ) AS delivered_value_contribution_pct
FROM labeled_quartiles
GROUP BY value_quartile, value_segment
ORDER BY value_quartile;

-- Business question: Which customers meet the defined high-value customer criteria?
-- Advanced SQL concept used: Layered CTEs, NTILE, RANK, and conditional filtering.
-- Metric definition: A high-value customer has at least 5 Delivered orders and belongs to Q4 based
-- on customer Delivered order value; results show the top 20 by value.
-- Assumptions: Frequency segmentation elsewhere uses all orders, but this high-value qualification uses
-- Delivered order count exactly as specified; customer_id is anonymized; value is not revenue or profit.
WITH customer_metrics AS (
    SELECT
        customer_id,
        COUNT(*) AS total_orders,
        COUNT(*) FILTER (WHERE order_status = 'Delivered') AS delivered_orders,
        COALESCE(
            SUM(total) FILTER (WHERE order_status = 'Delivered'),
            0
        ) AS delivered_order_value
    FROM clean_orders
    GROUP BY customer_id
), quartiled_customers AS (
    SELECT
        customer_id,
        total_orders,
        delivered_orders,
        delivered_order_value,
        NTILE(4) OVER (
            ORDER BY delivered_order_value, customer_id
        ) AS value_quartile
    FROM customer_metrics
), qualified_customers AS (
    SELECT
        customer_id,
        total_orders,
        delivered_orders,
        delivered_order_value,
        value_quartile,
        RANK() OVER (
            ORDER BY delivered_order_value DESC
        ) AS delivered_value_rank
    FROM quartiled_customers
    WHERE delivered_orders >= 5
      AND value_quartile = 4
)
SELECT
    customer_id,
    total_orders,
    delivered_orders,
    ROUND(delivered_order_value, 2) AS delivered_order_value,
    'Q4 (Highest)' AS value_segment,
    delivered_value_rank
FROM qualified_customers
ORDER BY delivered_value_rank, customer_id
LIMIT 20;

-- Business question: Which customers contribute the greatest share of delivered order value?
-- Advanced SQL concept used: Layered CTEs, percent-of-total window, and cumulative running total.
-- Metric definition: Customer contribution is Delivered order value divided by total Delivered order
-- value; cumulative contribution follows descending customer value; results show the top 20.
-- Assumptions: Only Delivered orders contribute financially; ties use customer_id for deterministic
-- ordering; delivered order value is not revenue or profit.
WITH customer_delivered_value AS (
    SELECT
        customer_id,
        COUNT(*) AS delivered_orders,
        SUM(total) AS delivered_order_value
    FROM clean_orders
    WHERE order_status = 'Delivered'
    GROUP BY customer_id
), customer_contribution AS (
    SELECT
        customer_id,
        delivered_orders,
        delivered_order_value,
        100.0 * delivered_order_value
            / SUM(delivered_order_value) OVER () AS delivered_value_contribution_pct,
        100.0 * SUM(delivered_order_value) OVER (
            ORDER BY delivered_order_value DESC, customer_id
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) / SUM(delivered_order_value) OVER () AS cumulative_delivered_value_pct
    FROM customer_delivered_value
)
SELECT
    customer_id,
    delivered_orders,
    ROUND(delivered_order_value, 2) AS delivered_order_value,
    ROUND(delivered_value_contribution_pct, 4)
        AS delivered_value_contribution_pct,
    ROUND(cumulative_delivered_value_pct, 2)
        AS cumulative_delivered_value_pct
FROM customer_contribution
ORDER BY delivered_order_value DESC, customer_id
LIMIT 20;

-- ==================================================
-- D. Operational Benchmarking
-- ==================================================

-- Business question: How does each outlet's kitchen preparation time compare with its brand average?
-- Advanced SQL concept used: CTE and weighted window benchmarks partitioned by brand.
-- Metric definition: Outlet and brand kitchen preparation averages use non-NULL measurements from
-- Delivered orders; variance is outlet average minus the order-weighted brand average.
-- Assumptions: Lower preparation time indicates faster performance but not necessarily better quality;
-- only Delivered orders are compared for a consistent completed-order population.
WITH outlet_kitchen_metrics AS (
    SELECT
        restaurant_id,
        restaurant_name,
        COUNT(kpt_duration_minutes) AS measured_orders,
        SUM(kpt_duration_minutes) AS total_kpt_minutes,
        AVG(kpt_duration_minutes) AS outlet_average_kpt_minutes
    FROM clean_orders
    WHERE order_status = 'Delivered'
    GROUP BY restaurant_id, restaurant_name
), outlet_brand_benchmarks AS (
    SELECT
        restaurant_id,
        restaurant_name,
        measured_orders,
        outlet_average_kpt_minutes,
        SUM(total_kpt_minutes) OVER (
            PARTITION BY restaurant_name
        ) / NULLIF(
            SUM(measured_orders) OVER (PARTITION BY restaurant_name),
            0
        ) AS brand_average_kpt_minutes
    FROM outlet_kitchen_metrics
)
SELECT
    restaurant_name,
    restaurant_id,
    measured_orders,
    ROUND(outlet_average_kpt_minutes, 2) AS outlet_average_kpt_minutes,
    ROUND(brand_average_kpt_minutes, 2) AS brand_average_kpt_minutes,
    ROUND(
        outlet_average_kpt_minutes - brand_average_kpt_minutes,
        2
    ) AS variance_from_brand_minutes,
    CASE
        WHEN outlet_average_kpt_minutes < brand_average_kpt_minutes THEN 'Faster than brand'
        WHEN outlet_average_kpt_minutes > brand_average_kpt_minutes THEN 'Slower than brand'
        ELSE 'At brand average'
    END AS brand_benchmark_status
FROM outlet_brand_benchmarks
ORDER BY restaurant_name, outlet_average_kpt_minutes, restaurant_id;

-- Business question: Which outlets have the strongest rider wait-time performance?
-- Advanced SQL concept used: CTE and RANK window function.
-- Metric definition: Average rider wait time uses non-NULL measurements from Delivered orders;
-- outlets are ranked ascending so rank 1 has the shortest average wait.
-- Assumptions: Lower wait time is operationally preferable; rankings with very small measured-order
-- counts should not be treated as equally reliable.
WITH outlet_rider_wait AS (
    SELECT
        restaurant_id,
        restaurant_name,
        COUNT(rider_wait_time_minutes) AS measured_orders,
        AVG(rider_wait_time_minutes) AS average_rider_wait_minutes
    FROM clean_orders
    WHERE order_status = 'Delivered'
    GROUP BY restaurant_id, restaurant_name
)
SELECT
    restaurant_id,
    restaurant_name,
    measured_orders,
    ROUND(average_rider_wait_minutes, 2) AS average_rider_wait_minutes,
    RANK() OVER (
        ORDER BY average_rider_wait_minutes
    ) AS rider_wait_performance_rank
FROM outlet_rider_wait
ORDER BY rider_wait_performance_rank, restaurant_id;

-- Business question: Which outlets perform faster or slower than overall operational benchmarks?
-- Advanced SQL concept used: Multiple CTEs, CROSS JOIN benchmark comparison, CASE, and conditional labels.
-- Metric definition: Outlet average kitchen preparation and rider wait times are compared with overall
-- Delivered-order averages; lower time is labeled Faster and higher time Slower.
-- Assumptions: Only non-NULL measurements on Delivered orders are used; performance labels describe
-- time only and do not measure food quality, accuracy, or statistical significance.
WITH outlet_operations AS (
    SELECT
        restaurant_id,
        restaurant_name,
        COUNT(*) AS delivered_orders,
        AVG(kpt_duration_minutes) AS average_kpt_minutes,
        AVG(rider_wait_time_minutes) AS average_rider_wait_minutes
    FROM clean_orders
    WHERE order_status = 'Delivered'
    GROUP BY restaurant_id, restaurant_name
), overall_benchmarks AS (
    SELECT
        AVG(kpt_duration_minutes) AS overall_average_kpt_minutes,
        AVG(rider_wait_time_minutes) AS overall_average_rider_wait_minutes
    FROM clean_orders
    WHERE order_status = 'Delivered'
)
SELECT
    outlet_operations.restaurant_id,
    outlet_operations.restaurant_name,
    outlet_operations.delivered_orders,
    ROUND(outlet_operations.average_kpt_minutes, 2) AS average_kpt_minutes,
    ROUND(overall_benchmarks.overall_average_kpt_minutes, 2)
        AS overall_average_kpt_minutes,
    CASE
        WHEN outlet_operations.average_kpt_minutes
            < overall_benchmarks.overall_average_kpt_minutes THEN 'Faster'
        WHEN outlet_operations.average_kpt_minutes
            > overall_benchmarks.overall_average_kpt_minutes THEN 'Slower'
        ELSE 'At benchmark'
    END AS kitchen_benchmark_status,
    ROUND(outlet_operations.average_rider_wait_minutes, 2)
        AS average_rider_wait_minutes,
    ROUND(overall_benchmarks.overall_average_rider_wait_minutes, 2)
        AS overall_average_rider_wait_minutes,
    CASE
        WHEN outlet_operations.average_rider_wait_minutes
            < overall_benchmarks.overall_average_rider_wait_minutes THEN 'Faster'
        WHEN outlet_operations.average_rider_wait_minutes
            > overall_benchmarks.overall_average_rider_wait_minutes THEN 'Slower'
        ELSE 'At benchmark'
    END AS rider_wait_benchmark_status
FROM outlet_operations
CROSS JOIN overall_benchmarks
ORDER BY outlet_operations.restaurant_name, outlet_operations.restaurant_id;

-- ==================================================
-- E. Dashboard Views
-- ==================================================

-- Business question: Which core metrics should appear on an executive dashboard summary?
-- Advanced SQL concept used: Conditional aggregation in a reusable PostgreSQL view.
-- Metric definition: Counts describe all orders and customers; success rate is Delivered orders divided
-- by total orders; financial fields use Delivered orders only.
-- Assumptions: total is delivered order value, not revenue or profit; the view returns one current-period row.
CREATE OR REPLACE VIEW vw_executive_kpis AS
SELECT
    COUNT(*) AS total_orders,
    COUNT(*) FILTER (WHERE order_status = 'Delivered') AS delivered_orders,
    COUNT(DISTINCT customer_id) AS unique_customers,
    ROUND(
        100.0 * COUNT(*) FILTER (WHERE order_status = 'Delivered')
        / NULLIF(COUNT(*), 0),
        2
    ) AS delivery_success_rate_pct,
    ROUND(
        COALESCE(SUM(total) FILTER (WHERE order_status = 'Delivered'), 0),
        2
    ) AS delivered_order_value,
    ROUND(
        AVG(total) FILTER (WHERE order_status = 'Delivered'),
        2
    ) AS average_delivered_order_value
FROM clean_orders;

-- Business question: Which monthly trend metrics should Power BI consume without reimplementing SQL logic?
-- Advanced SQL concept used: CTEs, LAG, running total, and CREATE OR REPLACE VIEW.
-- Metric definition: The view provides monthly demand, Delivered order value, month-over-month changes,
-- and cumulative Delivered order value.
-- Assumptions: The first month has NULL growth; financial fields use Delivered orders only; value is not
-- revenue or profit.
CREATE OR REPLACE VIEW vw_monthly_performance AS
WITH monthly_performance AS (
    SELECT
        DATE_TRUNC('month', order_date)::DATE AS order_month,
        COUNT(*) AS total_orders,
        COUNT(*) FILTER (WHERE order_status = 'Delivered') AS delivered_orders,
        COALESCE(
            SUM(total) FILTER (WHERE order_status = 'Delivered'),
            0
        ) AS delivered_order_value
    FROM clean_orders
    GROUP BY DATE_TRUNC('month', order_date)
), monthly_comparison AS (
    SELECT
        order_month,
        total_orders,
        delivered_orders,
        delivered_order_value,
        LAG(total_orders) OVER (ORDER BY order_month) AS prior_month_orders,
        LAG(delivered_order_value) OVER (
            ORDER BY order_month
        ) AS prior_month_delivered_value,
        SUM(delivered_order_value) OVER (
            ORDER BY order_month
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS cumulative_delivered_order_value
    FROM monthly_performance
)
SELECT
    order_month,
    total_orders,
    prior_month_orders,
    ROUND(
        100.0 * (total_orders - prior_month_orders)
        / NULLIF(prior_month_orders, 0),
        2
    ) AS month_over_month_order_growth_pct,
    delivered_orders,
    ROUND(delivered_order_value, 2) AS delivered_order_value,
    ROUND(prior_month_delivered_value, 2) AS prior_month_delivered_value,
    ROUND(
        100.0 * (delivered_order_value - prior_month_delivered_value)
        / NULLIF(prior_month_delivered_value, 0),
        2
    ) AS month_over_month_delivered_value_growth_pct,
    ROUND(cumulative_delivered_order_value, 2)
        AS cumulative_delivered_order_value
FROM monthly_comparison;

-- Business question: Which outlet metrics should support restaurant comparison visuals in Power BI?
-- Advanced SQL concept used: Conditional aggregation and CREATE OR REPLACE VIEW.
-- Metric definition: The view contains all-order demand, Delivered-order success and value, average value,
-- and Delivered-order operational averages for each restaurant outlet.
-- Assumptions: restaurant_id identifies an outlet; financial metrics use Delivered orders only; order value
-- is not revenue or profit.
CREATE OR REPLACE VIEW vw_restaurant_performance AS
SELECT
    restaurant_id,
    restaurant_name,
    COUNT(*) AS total_orders,
    COUNT(*) FILTER (WHERE order_status = 'Delivered') AS delivered_orders,
    ROUND(
        100.0 * COUNT(*) FILTER (WHERE order_status = 'Delivered')
        / NULLIF(COUNT(*), 0),
        2
    ) AS delivery_success_rate_pct,
    ROUND(
        COALESCE(SUM(total) FILTER (WHERE order_status = 'Delivered'), 0),
        2
    ) AS delivered_order_value,
    ROUND(
        AVG(total) FILTER (WHERE order_status = 'Delivered'),
        2
    ) AS average_delivered_order_value,
    ROUND(
        AVG(kpt_duration_minutes) FILTER (WHERE order_status = 'Delivered'),
        2
    ) AS average_kpt_minutes,
    ROUND(
        AVG(rider_wait_time_minutes) FILTER (WHERE order_status = 'Delivered'),
        2
    ) AS average_rider_wait_minutes
FROM clean_orders
GROUP BY restaurant_id, restaurant_name;

-- Business question: Which reusable customer attributes should support segmentation in Power BI?
-- Advanced SQL concept used: CTE, conditional aggregation, NTILE, CASE, and CREATE OR REPLACE VIEW.
-- Metric definition: Frequency segments use all orders (One-time 1, Repeat 2-4, Loyal 5+); value segments
-- use customer Delivered order value quartiles Q1-Q4; high-value requires 5+ Delivered orders and Q4.
-- Assumptions: Customers with no Delivered orders receive zero value; NTILE may split equal boundary values;
-- customer_id is anonymized; delivered order value is not revenue or profit.
CREATE OR REPLACE VIEW vw_customer_segments AS
WITH customer_metrics AS (
    SELECT
        customer_id,
        COUNT(*) AS total_orders,
        COUNT(*) FILTER (WHERE order_status = 'Delivered') AS delivered_orders,
        COALESCE(
            SUM(total) FILTER (WHERE order_status = 'Delivered'),
            0
        ) AS delivered_order_value
    FROM clean_orders
    GROUP BY customer_id
), quartiled_customers AS (
    SELECT
        customer_id,
        total_orders,
        delivered_orders,
        delivered_order_value,
        NTILE(4) OVER (
            ORDER BY delivered_order_value, customer_id
        ) AS value_quartile
    FROM customer_metrics
)
SELECT
    customer_id,
    total_orders,
    delivered_orders,
    ROUND(delivered_order_value, 2) AS delivered_order_value,
    CASE
        WHEN total_orders = 1 THEN 'One-time'
        WHEN total_orders BETWEEN 2 AND 4 THEN 'Repeat'
        ELSE 'Loyal'
    END AS frequency_segment,
    value_quartile,
    CASE value_quartile
        WHEN 1 THEN 'Q1 (Lowest)'
        WHEN 2 THEN 'Q2'
        WHEN 3 THEN 'Q3'
        WHEN 4 THEN 'Q4 (Highest)'
    END AS value_segment,
    delivered_orders >= 5 AND value_quartile = 4 AS is_high_value_customer
FROM quartiled_customers;

-- Business question: Which outlet benchmarks should support operational performance monitoring in Power BI?
-- Advanced SQL concept used: CTEs, weighted partitioned windows, RANK, CASE, and reusable view creation.
-- Metric definition: Delivered-order outlet averages are compared with weighted brand and overall averages;
-- rider wait rank orders outlets from shortest to longest average wait.
-- Assumptions: Lower duration is labeled Faster but does not measure quality; small outlet samples require
-- caution; only non-NULL Delivered-order measurements contribute to each benchmark.
CREATE OR REPLACE VIEW vw_operational_performance AS
WITH outlet_metrics AS (
    SELECT
        restaurant_id,
        restaurant_name,
        COUNT(*) AS delivered_orders,
        COUNT(kpt_duration_minutes) AS kpt_measured_orders,
        SUM(kpt_duration_minutes) AS total_kpt_minutes,
        AVG(kpt_duration_minutes) AS average_kpt_minutes,
        COUNT(rider_wait_time_minutes) AS rider_wait_measured_orders,
        SUM(rider_wait_time_minutes) AS total_rider_wait_minutes,
        AVG(rider_wait_time_minutes) AS average_rider_wait_minutes
    FROM clean_orders
    WHERE order_status = 'Delivered'
    GROUP BY restaurant_id, restaurant_name
), benchmarked_outlets AS (
    SELECT
        restaurant_id,
        restaurant_name,
        delivered_orders,
        kpt_measured_orders,
        average_kpt_minutes,
        SUM(total_kpt_minutes) OVER (
            PARTITION BY restaurant_name
        ) / NULLIF(
            SUM(kpt_measured_orders) OVER (PARTITION BY restaurant_name),
            0
        ) AS brand_average_kpt_minutes,
        SUM(total_kpt_minutes) OVER ()
            / NULLIF(SUM(kpt_measured_orders) OVER (), 0)
            AS overall_average_kpt_minutes,
        rider_wait_measured_orders,
        average_rider_wait_minutes,
        SUM(total_rider_wait_minutes) OVER ()
            / NULLIF(SUM(rider_wait_measured_orders) OVER (), 0)
            AS overall_average_rider_wait_minutes
    FROM outlet_metrics
)
SELECT
    restaurant_id,
    restaurant_name,
    delivered_orders,
    kpt_measured_orders,
    ROUND(average_kpt_minutes, 2) AS average_kpt_minutes,
    ROUND(brand_average_kpt_minutes, 2) AS brand_average_kpt_minutes,
    ROUND(overall_average_kpt_minutes, 2) AS overall_average_kpt_minutes,
    CASE
        WHEN average_kpt_minutes < overall_average_kpt_minutes THEN 'Faster'
        WHEN average_kpt_minutes > overall_average_kpt_minutes THEN 'Slower'
        ELSE 'At benchmark'
    END AS kitchen_benchmark_status,
    rider_wait_measured_orders,
    ROUND(average_rider_wait_minutes, 2) AS average_rider_wait_minutes,
    ROUND(overall_average_rider_wait_minutes, 2)
        AS overall_average_rider_wait_minutes,
    CASE
        WHEN average_rider_wait_minutes < overall_average_rider_wait_minutes THEN 'Faster'
        WHEN average_rider_wait_minutes > overall_average_rider_wait_minutes THEN 'Slower'
        ELSE 'At benchmark'
    END AS rider_wait_benchmark_status,
    RANK() OVER (
        ORDER BY average_rider_wait_minutes
    ) AS rider_wait_performance_rank
FROM benchmarked_outlets;

-- ==================================================
-- View Validation
-- ==================================================

-- Business question: Were all required dashboard views created and populated at the expected grain?
-- Advanced SQL concept used: UNION ALL validation query over reusable views.
-- Metric definition: Row counts should be 1 executive row, 5 monthly rows, 21 outlet rows in each
-- outlet view, and 11,607 customer rows.
-- Assumptions: Counts reflect the current clean_orders dataset and will change when source data changes.
SELECT 'vw_executive_kpis' AS view_name, COUNT(*) AS row_count
FROM vw_executive_kpis
UNION ALL
SELECT 'vw_monthly_performance', COUNT(*)
FROM vw_monthly_performance
UNION ALL
SELECT 'vw_restaurant_performance', COUNT(*)
FROM vw_restaurant_performance
UNION ALL
SELECT 'vw_customer_segments', COUNT(*)
FROM vw_customer_segments
UNION ALL
SELECT 'vw_operational_performance', COUNT(*)
FROM vw_operational_performance
ORDER BY view_name;
