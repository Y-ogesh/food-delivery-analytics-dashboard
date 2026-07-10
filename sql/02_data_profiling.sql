-- ==================================================
-- Dataset Size
-- ==================================================

SELECT COUNT(*) AS total_orders
FROM raw_order_history;


-- ==================================================
-- Count coloumns
-- ==================================================

SELECT COUNT(*)
FROM information_schema.columns
WHERE table_name='raw_order_history';


-- ==================================================
-- Inspect Schema
-- ==================================================

SELECT
    column_name,
    data_type
FROM information_schema.columns
WHERE table_name='raw_order_history'
ORDER BY ordinal_position;

-- ===========================================
-- Unique Business Entities
-- ===========================================

SELECT
    COUNT(DISTINCT restaurant_id) AS total_restaurants,
    COUNT(DISTINCT customer_id) AS total_customers,
    COUNT(DISTINCT city) AS total_cities
FROM raw_order_history;

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
    COUNT(*) AS total_orders
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
    MIN(order_placed_at) AS earliest_order,
    MAX(order_placed_at) AS latest_order
FROM raw_order_history;