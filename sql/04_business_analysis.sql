-- ==================================================
-- 04 Business Analysis
-- ==================================================
-- Project: Food Delivery Analytics Dashboard
-- Source: clean_orders only
-- Geography: Delhi NCR

\pset pager off

-- ==================================================
-- Executive KPIs
-- ==================================================

-- Business question: What is the overall scale and delivery performance of the dataset?
-- Metric definition: Total orders, delivered orders, unique customers, delivered-order
-- value, average delivered order value, and delivered orders as a percentage of all orders.
-- Assumptions: Each order_id is one order; total is final order value; financial metrics
-- include only orders whose status is Delivered.
SELECT
    COUNT(*) AS total_orders,
    COUNT(*) FILTER (WHERE order_status = 'Delivered') AS delivered_orders,
    COUNT(DISTINCT customer_id) AS unique_customers,
    ROUND(
        100.0 * COUNT(*) FILTER (WHERE order_status = 'Delivered') / COUNT(*),
        2
    ) AS delivery_success_rate_pct,
    ROUND(SUM(total) FILTER (WHERE order_status = 'Delivered'), 2)
        AS delivered_order_value,
    ROUND(AVG(total) FILTER (WHERE order_status = 'Delivered'), 2)
        AS average_delivered_order_value
FROM clean_orders;

-- Business question: How are orders distributed across final statuses?
-- Metric definition: Order count and percentage of all orders for each order status.
-- Assumptions: Each order_id is one order; statuses are used as standardized in clean_orders.
SELECT
    order_status,
    COUNT(*) AS order_count,
    ROUND(
        100.0 * COUNT(*) / (SELECT COUNT(*) FROM clean_orders),
        2
    ) AS share_of_orders_pct
FROM clean_orders
GROUP BY order_status
ORDER BY order_count DESC, order_status;

-- ==================================================
-- Restaurant Performance
-- ==================================================

-- Business question: Which restaurant outlets receive the most orders?
-- Metric definition: Count of all placed orders by restaurant_id and brand, limited to top 10 outlets.
-- Assumptions: restaurant_id identifies an outlet; all final statuses represent demand received.
SELECT
    restaurant_id,
    restaurant_name,
    COUNT(*) AS total_orders
FROM clean_orders
GROUP BY restaurant_id, restaurant_name
ORDER BY total_orders DESC, restaurant_id
LIMIT 10;

-- Business question: Which restaurant brands receive the most orders?
-- Metric definition: Count of all placed orders and distinct outlets by restaurant_name.
-- Assumptions: Restaurant names identify brands; all final statuses represent demand received.
SELECT
    restaurant_name,
    COUNT(DISTINCT restaurant_id) AS outlet_count,
    COUNT(*) AS total_orders
FROM clean_orders
GROUP BY restaurant_name
ORDER BY total_orders DESC, restaurant_name;

-- Business question: Which restaurant outlets generate the highest delivered order value?
-- Metric definition: Delivered-order count, sum of final order total, and average final order
-- total by outlet, limited to the top 10 by delivered order value.
-- Assumptions: Only Delivered orders are financial activity; total is order value, not audited revenue.
SELECT
    restaurant_id,
    restaurant_name,
    COUNT(*) AS delivered_orders,
    ROUND(SUM(total), 2) AS delivered_order_value,
    ROUND(AVG(total), 2) AS average_delivered_order_value
FROM clean_orders
WHERE order_status = 'Delivered'
GROUP BY restaurant_id, restaurant_name
ORDER BY delivered_order_value DESC, restaurant_id
LIMIT 10;

-- ==================================================
-- Customer Analysis
-- ==================================================

-- Business question: How large is the customer base and how often do customers order?
-- Metric definition: Unique customers, total orders, and average orders per unique customer.
-- Assumptions: customer_id consistently identifies an anonymized customer; all statuses count as attempts.
SELECT
    COUNT(DISTINCT customer_id) AS unique_customers,
    COUNT(*) AS total_orders,
    ROUND(COUNT(*)::NUMERIC / COUNT(DISTINCT customer_id), 2)
        AS average_orders_per_customer
FROM clean_orders;

-- Business question: What share of customers are repeat customers?
-- Metric definition: A repeat customer has at least two orders of any final status; repeat-customer
-- rate is repeat customers divided by all unique customers.
-- Assumptions: customer_id is stable across the full analysis period; order attempts count toward frequency.
SELECT
    COUNT(*) AS unique_customers,
    COUNT(*) FILTER (WHERE customer_order_count >= 2) AS repeat_customers,
    ROUND(
        100.0 * COUNT(*) FILTER (WHERE customer_order_count >= 2) / COUNT(*),
        2
    ) AS repeat_customer_rate_pct
FROM (
    SELECT
        customer_id,
        COUNT(*) AS customer_order_count
    FROM clean_orders
    GROUP BY customer_id
) AS customer_frequency;

-- Business question: Which anonymized customers have the highest delivered order value?
-- Metric definition: Delivered-order count and sum of final order total per customer, limited to top 10.
-- Assumptions: Only Delivered orders count financially; customer_id is anonymized and stable.
SELECT
    customer_id,
    COUNT(*) AS delivered_orders,
    ROUND(SUM(total), 2) AS delivered_order_value
FROM clean_orders
WHERE order_status = 'Delivered'
GROUP BY customer_id
ORDER BY delivered_order_value DESC, customer_id
LIMIT 10;

-- ==================================================
-- Time Analysis
-- ==================================================

-- Business question: Which days of the week have the highest order demand?
-- Metric definition: Count of all placed orders by weekday, ordered Monday through Sunday.
-- Assumptions: Demand includes every final status and uses the local order_placed_at timestamp.
SELECT
    EXTRACT(ISODOW FROM order_date)::INTEGER AS weekday_number,
    TO_CHAR(order_date, 'FMDay') AS weekday_name,
    COUNT(*) AS total_orders
FROM clean_orders
GROUP BY
    EXTRACT(ISODOW FROM order_date),
    TO_CHAR(order_date, 'FMDay')
ORDER BY weekday_number;

-- Business question: What are the peak ordering hours?
-- Metric definition: Count of all placed orders by hour of day on a 24-hour clock.
-- Assumptions: Demand includes every final status; order_hour reflects local source timestamps.
SELECT
    order_hour,
    COUNT(*) AS total_orders
FROM clean_orders
GROUP BY order_hour
ORDER BY total_orders DESC, order_hour;

-- Business question: How did monthly order demand and delivered order value change?
-- Metric definition: All order attempts, delivered orders, and delivered final order value by calendar month.
-- Assumptions: Partial months are not annualized; only Delivered orders contribute financial value.
SELECT
    DATE_TRUNC('month', order_date)::DATE AS order_month,
    COUNT(*) AS total_orders,
    COUNT(*) FILTER (WHERE order_status = 'Delivered') AS delivered_orders,
    ROUND(SUM(total) FILTER (WHERE order_status = 'Delivered'), 2)
        AS delivered_order_value
FROM clean_orders
GROUP BY DATE_TRUNC('month', order_date)
ORDER BY order_month;

-- ==================================================
-- Operational Performance
-- ==================================================

-- Business question: What are typical kitchen preparation and rider wait times for delivered orders?
-- Metric definition: Average kitchen preparation duration and average rider wait duration in minutes.
-- Assumptions: Only Delivered orders are used; averages exclude NULL measurements automatically.
SELECT
    ROUND(AVG(kpt_duration_minutes), 2) AS average_kpt_minutes,
    ROUND(AVG(rider_wait_time_minutes), 2) AS average_rider_wait_minutes
FROM clean_orders
WHERE order_status = 'Delivered';

-- Business question: How does delivered-order operational performance vary by distance?
-- Metric definition: Delivered orders, average kitchen time, and average rider wait time for source
-- distance categories, ordered by the cleaned numeric distance.
-- Assumptions: Only Delivered orders are compared; <1km is represented as 0.5 km in clean_orders.
SELECT
    distance_raw AS distance_category,
    distance_km,
    COUNT(*) AS delivered_orders,
    ROUND(AVG(kpt_duration_minutes), 2) AS average_kpt_minutes,
    ROUND(AVG(rider_wait_time_minutes), 2) AS average_rider_wait_minutes
FROM clean_orders
WHERE order_status = 'Delivered'
GROUP BY distance_raw, distance_km
ORDER BY distance_km, distance_category;

-- Business question: How consistently are restaurants marking orders ready?
-- Metric definition: Count and percentage of all orders for each order-ready marking outcome.
-- Assumptions: The source categories Correctly, Incorrectly, and Missed describe marking quality.
SELECT
    order_ready_marked,
    COUNT(*) AS order_count,
    ROUND(
        100.0 * COUNT(*) / (SELECT COUNT(*) FROM clean_orders),
        2
    ) AS share_of_orders_pct
FROM clean_orders
GROUP BY order_ready_marked
ORDER BY order_count DESC, order_ready_marked;

-- Business question: Which non-delivered outcomes occur most often?
-- Metric definition: Count of orders for every final status other than Delivered.
-- Assumptions: All non-Delivered statuses are operational exceptions, but not necessarily cancellations.
SELECT
    order_status,
    COUNT(*) AS exception_orders
FROM clean_orders
WHERE order_status <> 'Delivered'
GROUP BY order_status
ORDER BY exception_orders DESC, order_status;

-- ==================================================
-- Financial Analysis
-- ==================================================

-- Business question: What is the delivered-order financial summary?
-- Metric definition: Sum of subtotal, packaging charges, final total, and average final total for Delivered orders.
-- Assumptions: Only Delivered orders are financial activity; values describe order economics, not audited revenue.
SELECT
    COUNT(*) AS delivered_orders,
    ROUND(SUM(bill_subtotal), 2) AS delivered_bill_subtotal,
    ROUND(SUM(packaging_charges), 2) AS delivered_packaging_charges,
    ROUND(SUM(total), 2) AS delivered_order_value,
    ROUND(AVG(total), 2) AS average_delivered_order_value
FROM clean_orders
WHERE order_status = 'Delivered';

-- Business question: How much discount value is recorded on delivered orders by discount type?
-- Metric definition: Sum of each discount field and their combined total across Delivered orders.
-- Assumptions: NULL discount values represent no recorded amount and are treated as zero for addition.
SELECT
    ROUND(SUM(COALESCE(restaurant_discount_promo, 0)), 2)
        AS restaurant_promo_discount,
    ROUND(SUM(COALESCE(restaurant_discount_flat_offs, 0)), 2)
        AS restaurant_flat_off_discount,
    ROUND(SUM(COALESCE(gold_discount, 0)), 2) AS gold_discount,
    ROUND(SUM(COALESCE(brand_pack_discount, 0)), 2) AS brand_pack_discount,
    ROUND(
        SUM(
            COALESCE(restaurant_discount_promo, 0)
            + COALESCE(restaurant_discount_flat_offs, 0)
            + COALESCE(gold_discount, 0)
            + COALESCE(brand_pack_discount, 0)
        ),
        2
    ) AS total_recorded_discount
FROM clean_orders
WHERE order_status = 'Delivered';

-- Business question: Which subzones generate the highest delivered order value?
-- Metric definition: Delivered-order count, sum of final order total, and average final order total by subzone.
-- Assumptions: Only Delivered orders are financial activity; subzone is the source market-area label.
SELECT
    subzone,
    COUNT(*) AS delivered_orders,
    ROUND(SUM(total), 2) AS delivered_order_value,
    ROUND(AVG(total), 2) AS average_delivered_order_value
FROM clean_orders
WHERE order_status = 'Delivered'
GROUP BY subzone
ORDER BY delivered_order_value DESC, subzone;

-- ==================================================
-- Customer Satisfaction
-- ==================================================

-- Business question: What is the overall customer rating among orders with submitted ratings?
-- Metric definition: Rated-order count, rating completion rate, and average submitted rating.
-- Assumptions: NULL means no rating submitted; the average is not representative of all customers.
SELECT
    COUNT(rating) AS rated_orders,
    ROUND(100.0 * COUNT(rating) / COUNT(*), 2) AS rating_completion_rate_pct,
    ROUND(AVG(rating), 2) AS average_submitted_rating
FROM clean_orders;

-- Business question: How are submitted ratings distributed?
-- Metric definition: Count and percentage of rated orders for each rating value.
-- Assumptions: NULL ratings are excluded; percentages use only orders with a submitted rating.
SELECT
    rating,
    COUNT(*) AS rated_orders,
    ROUND(
        100.0 * COUNT(*) / (SELECT COUNT(rating) FROM clean_orders),
        2
    ) AS share_of_ratings_pct
FROM clean_orders
WHERE rating IS NOT NULL
GROUP BY rating
ORDER BY rating DESC;

-- Business question: Which customer complaint categories are reported most often?
-- Metric definition: Count of orders by non-NULL customer complaint tag.
-- Assumptions: Missing tags mean no recorded complaint tag, not proof that no issue occurred.
SELECT
    customer_complaint_tag,
    COUNT(*) AS complaint_count
FROM clean_orders
WHERE customer_complaint_tag IS NOT NULL
GROUP BY customer_complaint_tag
ORDER BY complaint_count DESC, customer_complaint_tag;
