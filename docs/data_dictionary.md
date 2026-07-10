# Food Delivery Analytics Project Data Dictionary

## Project

**Dataset:** Food Delivery Order History Dataset  
**Source:** Kaggle  
**Raw Table:** `raw_order_history`

## Purpose

This data dictionary documents the raw imported dataset before transformation. It helps reviewers understand what each field represents, how it may be used in analysis, and which columns require cleaning before production-style reporting.

## Important Assumptions

- `restaurant_id` represents a restaurant location or outlet. The dataset has 21 distinct restaurant IDs but only 6 distinct restaurant names.
- `order_id` is treated as the unique order identifier because profiling found no duplicate order IDs.
- `order_placed_at` is stored as text in the raw table and must be parsed into a timestamp before time-based analysis.
- All records currently belong to `Delhi NCR`, so the dataset should be described as Delhi NCR food delivery activity.
- Ratings, reviews, complaints, and cancellation/rejection reasons are optional fields and are not complete for all orders.

## Raw Table: `raw_order_history`

| Column | Raw Data Type | Description | Cleaning / Analysis Notes |
|---|---|---|---|
| `restaurant_id` | `BIGINT` | Unique identifier for a restaurant location or outlet. | Use as the primary restaurant entity key. |
| `restaurant_name` | `TEXT` | Restaurant brand or display name. | Multiple restaurant IDs can share the same name. |
| `subzone` | `TEXT` | Local delivery area or neighborhood grouping. | Useful for local market analysis. |
| `city` | `TEXT` | City or city region associated with the order. | Current dataset contains only `Delhi NCR`. |
| `order_id` | `BIGINT` | Unique identifier for each order. | Profiling found no duplicate order IDs. |
| `order_placed_at` | `TEXT` | Timestamp string showing when the order was placed. | Convert using `to_timestamp(order_placed_at, 'HH12:MI AM, Month DD YYYY')`. |
| `order_status` | `TEXT` | Final or current order outcome. | Values include `Delivered`, `Rejected`, `Returned`, `Picked up`, `Return cancelled`, and `Timed out`. |
| `delivery` | `TEXT` | Delivery fulfillment method. | Current dataset contains only `Zomato Delivery`. |
| `distance` | `TEXT` | Delivery distance stored as text, such as `2km` or `<1km`. | Convert to numeric kilometers during cleaning. |
| `items_in_order` | `TEXT` | Comma-separated text description of items and quantities. | Useful for text analysis later; not normalized at this stage. |
| `instructions` | `TEXT` | Customer-provided delivery or preparation instructions. | Optional free-text field. |
| `discount_construct` | `TEXT` | Description of the promotional discount structure. | Text field; may require parsing for promo analysis. |
| `bill_subtotal` | `NUMERIC(10,2)` | Order subtotal before discounts and selected charges. | Financial metric. |
| `packaging_charges` | `NUMERIC(10,2)` | Packaging fee charged on the order. | Financial metric. |
| `restaurant_discount_promo` | `NUMERIC(10,2)` | Promotional discount funded by the restaurant. | Financial metric. |
| `restaurant_discount_flat_offs` | `NUMERIC(10,2)` | Flat-off, freebie, or other restaurant discount amount. | Financial metric. |
| `gold_discount` | `NUMERIC(10,2)` | Loyalty or membership discount amount. | Financial metric. |
| `brand_pack_discount` | `NUMERIC(10,2)` | Brand pack discount amount. | Financial metric. |
| `total` | `NUMERIC(10,2)` | Final order total after applicable charges and discounts. | Primary revenue-like field for order value analysis. |
| `rating` | `NUMERIC(3,1)` | Customer rating for the order. | Sparse field; present for 11.68% of orders. |
| `review` | `TEXT` | Customer review text. | Optional free-text feedback field. |
| `cancellation_rejection_reason` | `TEXT` | Reason associated with cancellation or rejection outcomes. | Sparse field; use only for exception analysis. |
| `restaurant_compensation_cancellation` | `NUMERIC(10,2)` | Compensation amount related to cancellation. | Financial exception metric. |
| `restaurant_penalty_rejection` | `NUMERIC(10,2)` | Penalty amount related to rejection. | Financial exception metric. |
| `kpt_duration_minutes` | `NUMERIC(10,2)` | Kitchen preparation time in minutes. | Operational performance metric. |
| `rider_wait_time_minutes` | `NUMERIC(10,2)` | Rider wait time in minutes. | Operational performance metric. |
| `order_ready_marked` | `TEXT` | Whether the restaurant marked the order-ready status correctly. | Values include `Correctly`, `Incorrectly`, and `Missed`. |
| `customer_complaint_tag` | `TEXT` | Complaint category associated with the order. | Sparse field; use for customer issue analysis. |
| `customer_id` | `TEXT` | Hashed or anonymized customer identifier. | Enables repeat-customer analysis without exposing personal details. |
