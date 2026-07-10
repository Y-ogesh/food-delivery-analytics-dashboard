-- ==================================================
-- 02 Data Profiling
-- ==================================================
-- Project: Food Delivery Analytics Project
--
-- Purpose:
-- Inspect the raw imported order history dataset before building
-- cleaning, analysis, and dashboard layers.
--
-- Business context:
-- Profiling helps confirm whether the dataset is complete, reliable,
-- and suitable for operational and financial analysis.
--
-- Geography:
-- The source data represents Delhi NCR food delivery activity.

-- ==================================================
-- Dataset Size
-- ==================================================

SELECT COUNT(*) AS total_orders
FROM raw_order_history;


-- ==================================================
-- Count Columns
-- ==================================================

SELECT COUNT(*) AS total_columns
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'raw_order_history';


-- ==================================================
-- Inspect Schema
-- ==================================================

SELECT
    column_name,
    data_type
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'raw_order_history'
ORDER BY ordinal_position;

-- ===========================================
-- Unique Business Entities
-- ===========================================

SELECT
    COUNT(DISTINCT restaurant_id) AS total_restaurant_locations,
    COUNT(DISTINCT restaurant_name) AS total_restaurant_brands,
    COUNT(DISTINCT customer_id) AS total_customers,
    COUNT(DISTINCT city) AS total_cities,
    COUNT(DISTINCT subzone) AS total_subzones
FROM raw_order_history;

-- ===========================================
-- City Coverage
-- ===========================================

SELECT
    city,
    COUNT(*) AS total_orders
FROM raw_order_history
GROUP BY city
ORDER BY total_orders DESC;

-- ===========================================
-- Ratings Completeness
-- ===========================================

SELECT
    COUNT(*) AS total_orders,
    COUNT(rating) AS ratings_present,
    COUNT(*) - COUNT(rating) AS ratings_missing,
    ROUND(
            (COUNT(rating) * 100.0) / COUNT(*),
            2
    ) AS rating_completion_percentage
FROM raw_order_history;

-- ===========================================
-- Order Status Distribution
-- ===========================================

SELECT
    order_status,
    COUNT(*) AS total_orders,
    ROUND(
            COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (),
            2
    ) AS order_percentage
FROM raw_order_history
GROUP BY order_status
ORDER BY total_orders DESC;


-- ===========================================
-- Duplicate Order IDs
-- ===========================================

SELECT
    order_id,
    COUNT(*) AS occurrences
FROM raw_order_history
GROUP BY order_id
HAVING COUNT(*) > 1
ORDER BY occurrences DESC;

-- ===========================================
-- Dataset Date Range
-- ===========================================

SELECT
    MIN(order_placed_at) AS earliest_order_text,
    MAX(order_placed_at) AS latest_order_text
FROM raw_order_history;

-- Correct date range after parsing the source text into a timestamp.
SELECT
    MIN(
            to_timestamp(order_placed_at, 'HH12:MI AM, Month DD YYYY')
    ) AS earliest_order_timestamp,
    MAX(
            to_timestamp(order_placed_at, 'HH12:MI AM, Month DD YYYY')
    ) AS latest_order_timestamp
FROM raw_order_history;

-- ===========================================
-- Feedback and Issue Completeness
-- ===========================================

SELECT
    COUNT(*) AS total_orders,
    COUNT(review) AS reviews_present,
    COUNT(customer_complaint_tag) AS complaint_tags_present,
    COUNT(cancellation_rejection_reason) AS cancellation_rejection_reasons_present
FROM raw_order_history;
