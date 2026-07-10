-- Create database
CREATE DATABASE food_delivery_analytics;

-- Create staging table
CREATE TABLE raw_order_history (
                                   restaurant_id BIGINT,
                                   restaurant_name TEXT,
                                   subzone TEXT,
                                   city TEXT,
                                   order_id BIGINT,
                                   order_placed_at TEXT,
                                   order_status TEXT,
                                   delivery TEXT,
                                   distance TEXT,
                                   items_in_order TEXT,
                                   instructions TEXT,
                                   discount_construct TEXT,
                                   bill_subtotal NUMERIC(10,2),
                                   packaging_charges NUMERIC(10,2),
                                   restaurant_discount_promo NUMERIC(10,2),
                                   restaurant_discount_flat_offs NUMERIC(10,2),
                                   gold_discount NUMERIC(10,2),
                                   brand_pack_discount NUMERIC(10,2),
                                   total NUMERIC(10,2),
                                   rating NUMERIC(3,1),
                                   review TEXT,
                                   cancellation_rejection_reason TEXT,
                                   restaurant_compensation_cancellation NUMERIC(10,2),
                                   restaurant_penalty_rejection NUMERIC(10,2),
                                   kpt_duration_minutes NUMERIC(10,2),
                                   rider_wait_time_minutes NUMERIC(10,2),
                                   order_ready_marked TEXT,
                                   customer_complaint_tag TEXT,
                                   customer_id TEXT
);

-- ===========================================
-- Data Import
-- ===========================================

-- Import the CSV file into raw_order_history.
-- The CSV is located in the project's data/ folder.
--
-- Example:
-- COPY raw_order_history
-- FROM '<your-local-path>/data/order_history_kaggle_data.csv'
-- DELIMITER ','
-- CSV HEADER;
-- Verify import

SELECT COUNT(*)
FROM raw_order_history;