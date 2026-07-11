-- ==================================================
-- 03 Data Cleaning
-- ==================================================
-- Project: Food Delivery Analytics Project
--
-- Purpose:
-- Build an analytics-ready staging table named clean_orders without
-- updating, altering, or rewriting the immutable raw_order_history table.
--
-- Business context:
-- A clean staging layer gives analysts and dashboard tools a stable,
-- typed dataset for order, revenue, customer, and operational analysis.
--
-- Geography:
-- The source data represents Delhi NCR food delivery activity. Preserve
-- raw restaurant, city, subzone, and location values during cleaning.

-- ==================================================
-- Rebuild Clean Staging Table
-- ==================================================
-- This script only drops and recreates clean_orders.
-- raw_order_history is treated as immutable raw source data.

DROP TABLE IF EXISTS clean_orders;

CREATE TABLE clean_orders AS
SELECT
    -- Preserve restaurant location identifier from the raw source.
    restaurant_id,

    -- Trim text fields to remove accidental leading/trailing whitespace.
    NULLIF(TRIM(restaurant_name), '') AS restaurant_name,
    NULLIF(TRIM(subzone), '') AS subzone,
    NULLIF(TRIM(city), '') AS city,

    -- Preserve the source order identifier.
    order_id,

    -- Convert source timestamp text into a PostgreSQL timestamp.
    to_timestamp(
        order_placed_at,
        'HH12:MI AM, Month DD YYYY'
    )::TIMESTAMP AS order_placed_at,

    -- Add date and time attributes that will simplify later analysis.
    to_timestamp(
        order_placed_at,
        'HH12:MI AM, Month DD YYYY'
    )::DATE AS order_date,
    EXTRACT(
        HOUR FROM to_timestamp(order_placed_at, 'HH12:MI AM, Month DD YYYY')
    )::INTEGER AS order_hour,

    -- Standardize categorical text by trimming whitespace while preserving
    -- source category meaning.
    NULLIF(TRIM(order_status), '') AS order_status,
    NULLIF(TRIM(delivery), '') AS delivery_method,

    -- Preserve the original distance label for auditability.
    NULLIF(TRIM(distance), '') AS distance_raw,

    -- Convert distance text into numeric kilometers.
    -- '<1km' is approximated as 0.5 km based on the project decision that
    -- it represents an order less than one kilometer away.
    CASE
        WHEN TRIM(distance) = '<1km' THEN 0.5
        WHEN TRIM(distance) ~ '^[0-9]+km$'
            THEN REPLACE(TRIM(distance), 'km', '')::NUMERIC(5,2)
        ELSE NULL
    END AS distance_km,

    -- Trim optional free-text fields and preserve NULL when information is
    -- missing or blank.
    NULLIF(TRIM(items_in_order), '') AS items_in_order,
    NULLIF(TRIM(instructions), '') AS instructions,
    NULLIF(TRIM(discount_construct), '') AS discount_construct,

    -- Preserve numeric financial fields from the raw source.
    bill_subtotal,
    packaging_charges,
    restaurant_discount_promo,
    restaurant_discount_flat_offs,
    gold_discount,
    brand_pack_discount,
    total,

    -- Preserve customer feedback fields. Rating remains numeric; optional
    -- text feedback is trimmed and blank values become NULL.
    rating,
    NULLIF(TRIM(review), '') AS review,
    NULLIF(TRIM(cancellation_rejection_reason), '') AS cancellation_rejection_reason,

    -- Preserve operational financial adjustment fields.
    restaurant_compensation_cancellation,
    restaurant_penalty_rejection,

    -- Preserve operational duration metrics.
    kpt_duration_minutes,
    rider_wait_time_minutes,

    -- Trim operational status and complaint fields.
    NULLIF(TRIM(order_ready_marked), '') AS order_ready_marked,
    NULLIF(TRIM(customer_complaint_tag), '') AS customer_complaint_tag,

    -- Trim anonymized customer identifier.
    NULLIF(TRIM(customer_id), '') AS customer_id
FROM raw_order_history;

-- Add a primary key to enforce one row per order in the cleaned layer.
ALTER TABLE clean_orders
ADD CONSTRAINT clean_orders_pk PRIMARY KEY (order_id);

-- ==================================================
-- Validation Queries
-- ==================================================

-- Compare raw and cleaned row counts. These should match.
SELECT
    (SELECT COUNT(*) FROM raw_order_history) AS raw_row_count,
    (SELECT COUNT(*) FROM clean_orders) AS clean_row_count;

-- Confirm duplicate order IDs do not exist in the cleaned table.
SELECT
    order_id,
    COUNT(*) AS occurrences
FROM clean_orders
GROUP BY order_id
HAVING COUNT(*) > 1
ORDER BY occurrences DESC;

-- Validate null counts for important cleaned fields.
SELECT
    COUNT(*) AS total_rows,
    COUNT(*) FILTER (WHERE order_id IS NULL) AS order_id_nulls,
    COUNT(*) FILTER (WHERE order_placed_at IS NULL) AS order_placed_at_nulls,
    COUNT(*) FILTER (WHERE restaurant_id IS NULL) AS restaurant_id_nulls,
    COUNT(*) FILTER (WHERE customer_id IS NULL) AS customer_id_nulls,
    COUNT(*) FILTER (WHERE order_status IS NULL) AS order_status_nulls,
    COUNT(*) FILTER (WHERE distance_km IS NULL) AS distance_km_nulls,
    COUNT(*) FILTER (WHERE total IS NULL) AS total_nulls,
    COUNT(*) FILTER (WHERE rating IS NULL) AS rating_nulls,
    COUNT(*) FILTER (WHERE review IS NULL) AS review_nulls,
    COUNT(*) FILTER (WHERE customer_complaint_tag IS NULL) AS complaint_tag_nulls,
    COUNT(*) FILTER (WHERE cancellation_rejection_reason IS NULL) AS cancellation_rejection_reason_nulls
FROM clean_orders;

-- Validate the converted date range.
SELECT
    MIN(order_placed_at) AS earliest_order,
    MAX(order_placed_at) AS latest_order
FROM clean_orders;

-- Review distance conversion results, including the '<1km' approximation.
SELECT
    distance_raw,
    distance_km,
    COUNT(*) AS total_orders
FROM clean_orders
GROUP BY
    distance_raw,
    distance_km
ORDER BY
    distance_km,
    distance_raw;
