-- ==================================================
-- 06 Customer Spending Extraction
-- ==================================================
-- Project: Food Delivery Analytics Dashboard
-- Milestone: Statistical Hypothesis Testing — Customer Spending Analysis
-- Source: public.clean_orders only
--
-- Business question:
-- Does average delivered order value per customer differ between customers
-- with exactly one Delivered order and customers with two or more?
--
-- Extraction grain:
-- One row per customer with at least one successfully Delivered order.
--
-- Metric definition:
-- average_delivered_order_value is the arithmetic mean of total across a
-- customer's Delivered orders. customer_segment is One-time for exactly one
-- Delivered order and Repeat for two or more Delivered orders.
--
-- Assumptions:
-- customer_id consistently identifies an anonymized customer; order_id is
-- unique; total is delivered order value, not revenue or profit; hypothesis
-- testing is intentionally outside the scope of this extraction milestone.
SELECT
    customer_id,
    COUNT(order_id) AS delivered_order_count,
    AVG(total)::DOUBLE PRECISION AS average_delivered_order_value,
    CASE
        WHEN COUNT(order_id) = 1 THEN 'One-time'
        ELSE 'Repeat'
    END AS customer_segment
FROM public.clean_orders
WHERE order_status = 'Delivered'
GROUP BY customer_id
ORDER BY customer_id;
