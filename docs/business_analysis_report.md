# Business Analysis Report

## Project Scope

This report answers business questions using only the analytics-ready `clean_orders` table. The data covers 21,321 Delhi NCR orders placed from September 1, 2024 through January 31, 2025. Financial analysis includes only orders with a final status of `Delivered`. The `total` field is described as **delivered order value**, not audited revenue or restaurant payout.

## Executive KPIs

### 1. What is the overall scale and delivery performance?

**SQL result**

| Total orders | Delivered orders | Unique customers | Delivery success rate | Delivered order value | Average delivered order value |
|---:|---:|---:|---:|---:|---:|
| 21,321 | 21,131 | 11,607 | 99.11% | 14,423,379.76 | 682.57 |

**Interpretation:** Almost all recorded orders were delivered, and the typical delivered order generated about 683 in final order value.

**Business significance:** These values establish the baseline scale, fulfillment performance, and value of the operation for later comparisons.

**Limitations:** Currency is not explicitly documented in the source. Order value is not the same as recognized revenue, payout, or profit.

### 2. How are orders distributed across final statuses?

**SQL result**

| Status | Orders | Share |
|---|---:|---:|
| Delivered | 21,131 | 99.11% |
| Rejected | 158 | 0.74% |
| Returned | 25 | 0.12% |
| Picked up | 3 | 0.01% |
| Return cancelled | 3 | 0.01% |
| Timed out | 1 | 0.00% |

**Interpretation:** Rejections are the largest exception category, although they account for less than 1% of orders.

**Business significance:** Operational improvement work should examine rejection drivers first because they represent 83% of the 190 non-delivered outcomes.

**Limitations:** Final status labels describe outcomes but do not by themselves identify root causes.

## Restaurant Performance

### 3. Which restaurant outlets receive the most orders?

**SQL result**

| Rank | Restaurant ID | Brand | Orders |
|---:|---:|---|---:|
| 1 | 20659868 | Aura Pizzas | 4,614 |
| 2 | 20635699 | Aura Pizzas | 4,418 |
| 3 | 20554001 | Swaad | 2,781 |
| 4 | 20882652 | Aura Pizzas | 2,545 |
| 5 | 21077127 | Aura Pizzas | 2,051 |
| 6 | 20320607 | Swaad | 1,774 |
| 7 | 20882713 | Swaad | 1,079 |
| 8 | 21173951 | Aura Pizzas | 920 |
| 9 | 21309083 | Swaad | 698 |
| 10 | 20968206 | Dilli Burger Adda | 109 |

**Interpretation:** Aura Pizzas outlet 20659868 leads order demand, closely followed by outlet 20635699.

**Business significance:** Staffing, inventory, and availability planning should prioritize the highest-volume outlets.

**Limitations:** Order count measures demand attempts, not delivered sales, and does not adjust for outlet operating hours or capacity.

### 4. Which restaurant brands receive the most orders?

**SQL result**

| Brand | Outlets | Orders |
|---|---:|---:|
| Aura Pizzas | 5 | 14,548 |
| Swaad | 4 | 6,332 |
| Dilli Burger Adda | 4 | 227 |
| Tandoori Junction | 4 | 154 |
| The Chicken Junction | 3 | 32 |
| Masala Junction | 1 | 28 |

**Interpretation:** Aura Pizzas and Swaad together account for 97.93% of all orders.

**Business significance:** Portfolio results are highly dependent on these two brands; smaller brands may need separate growth and viability analysis.

**Limitations:** Brands have different outlet counts and likely different operating periods, so totals do not measure like-for-like outlet productivity.

### 5. Which outlets generate the highest delivered order value?

**SQL result**

| Rank | Restaurant ID | Brand | Delivered orders | Delivered order value | Average value |
|---:|---:|---|---:|---:|---:|
| 1 | 20659868 | Aura Pizzas | 4,574 | 3,449,430.60 | 754.14 |
| 2 | 20635699 | Aura Pizzas | 4,369 | 3,065,554.62 | 701.66 |
| 3 | 20882652 | Aura Pizzas | 2,523 | 1,946,571.08 | 771.53 |
| 4 | 20554001 | Swaad | 2,765 | 1,531,361.51 | 553.84 |
| 5 | 21077127 | Aura Pizzas | 2,035 | 1,498,055.32 | 736.15 |
| 6 | 20320607 | Swaad | 1,750 | 928,344.73 | 530.48 |
| 7 | 21173951 | Aura Pizzas | 916 | 687,580.04 | 750.63 |
| 8 | 20882713 | Swaad | 1,070 | 597,911.64 | 558.80 |
| 9 | 21309083 | Swaad | 697 | 466,855.49 | 669.81 |
| 10 | 21143186 | Tandoori Junction | 71 | 64,495.70 | 908.39 |

**Interpretation:** The highest-value outlets broadly mirror the demand ranking. Some low-volume outlets have high average values, but their samples are much smaller.

**Business significance:** Outlet 20659868 is the largest value contributor, while outlet-level average values can help identify mix and upsell opportunities.

**Limitations:** Average value should not be compared without considering volume; delivered order value is not profit.

## Customer Analysis

### 6. How large is the customer base and how often do customers order?

**SQL result:** 11,607 unique customers placed 21,321 orders, averaging 1.84 orders per customer.

**Interpretation:** The average customer placed fewer than two orders during the five-month period.

**Business significance:** There is room to increase ordering frequency through retention and reactivation programs.

**Limitations:** The observation window is short and customer identifiers may not capture activity outside this dataset.

### 7. What share of customers are repeat customers?

**SQL result:** 3,894 of 11,607 customers placed at least two orders, a repeat-customer rate of 33.55%.

**Interpretation:** About one-third of observed customers returned for another order.

**Business significance:** Repeat customers form a meaningful base, while the larger one-time group is a clear retention opportunity.

**Limitations:** The definition includes all order attempts, regardless of final status, and does not adjust for when a customer first appeared.

### 8. Which customers have the highest delivered order value?

**SQL result:** The top customer placed 60 delivered orders worth 27,767.93. Across the top 10 customers, delivered value ranged from 18,128.11 to 27,767.93 and delivered frequency ranged from 13 to 60 orders.

**Interpretation:** High-value customers arise from both frequent ordering and high order value.

**Business significance:** This group is suitable for retention research and loyalty targeting using privacy-safe identifiers.

**Limitations:** Customer IDs are intentionally anonymized; this result does not estimate margin or customer lifetime value beyond the dataset period.

## Time Analysis

### 9. Which weekdays have the highest demand?

**SQL result**

| Monday | Tuesday | Wednesday | Thursday | Friday | Saturday | Sunday |
|---:|---:|---:|---:|---:|---:|---:|
| 2,196 | 2,885 | 3,077 | 2,879 | 3,403 | 3,923 | 2,958 |

**Interpretation:** Saturday is the busiest day, followed by Friday; Monday is the quietest.

**Business significance:** Labor, ingredient preparation, and delivery readiness should be strongest heading into Friday and Saturday.

**Limitations:** Totals are not normalized for the number of each weekday in the date range or restaurant availability.

### 10. What are the peak ordering hours?

**SQL result:** 20:00 is the busiest hour with 2,912 orders, followed by 19:00 with 2,419 and 21:00 with 2,296. Hours 18:00–23:59 contain 12,463 orders, or 58.45% of demand.

**Interpretation:** Demand has a clear dinner peak centered around 8 PM.

**Business significance:** Kitchen staffing, rider coordination, and stock availability should be aligned with the evening surge.

**Limitations:** The source does not provide a timezone field; analysis treats timestamps as local business time.

### 11. How did monthly demand and delivered order value change?

**SQL result**

| Month | Total orders | Delivered orders | Delivered order value |
|---|---:|---:|---:|
| 2024-09 | 4,241 | 4,191 | 2,595,841.19 |
| 2024-10 | 4,277 | 4,249 | 2,975,504.91 |
| 2024-11 | 4,491 | 4,451 | 2,995,737.13 |
| 2024-12 | 4,301 | 4,264 | 3,064,972.87 |
| 2025-01 | 4,011 | 3,976 | 2,791,323.66 |

**Interpretation:** Order volume peaked in November, while delivered order value peaked in December.

**Business significance:** December generated more value with fewer orders than November, pointing to a stronger order-value mix.

**Limitations:** Five months are insufficient to establish seasonality, and monthly results are not adjusted for days or outlet availability.

## Operational Performance

### 12. What are typical preparation and rider wait times?

**SQL result:** Delivered orders averaged 17.34 minutes of kitchen preparation time and 4.83 minutes of rider wait time.

**Interpretation:** Rider waiting represents a material handoff interval relative to kitchen preparation time.

**Business significance:** These baselines can support outlet benchmarking and order-ready process improvements.

**Limitations:** Averages can hide outliers and do not prove why waits occurred.

### 13. How does operational performance vary by distance?

**SQL result:** Across distance categories, average kitchen preparation time ranged from 16.83 minutes at 1 km to 19.03 minutes at 18 km among categories with at least 20 delivered orders. Average rider wait rose from 4.29 minutes at 1 km to 6.41 minutes at 16 km; the 19 km category averaged 7.22 minutes but contained only 18 orders.

**Interpretation:** Kitchen time is relatively stable across common distances, while rider wait generally increases in longer-distance categories.

**Business significance:** Longer-distance orders may require closer dispatch timing and handoff coordination.

**Limitations:** Distance should not directly cause kitchen time. Categories above 10 km have small samples, and `<1km` is approximated as 0.5 km.

### 14. How consistently are orders marked ready?

**SQL result**

| Ready marking | Orders | Share |
|---|---:|---:|
| Correctly | 19,087 | 89.52% |
| Incorrectly | 1,895 | 8.89% |
| Missed | 339 | 1.59% |

**Interpretation:** 10.48% of orders were marked incorrectly or missed.

**Business significance:** More consistent order-ready marking could improve rider dispatch and reduce avoidable waiting.

**Limitations:** The field records the marking outcome, not the reason for incorrect or missed actions.

### 15. Which non-delivered outcomes occur most often?

**SQL result:** 158 orders were rejected, 25 returned, 3 picked up, 3 return cancelled, and 1 timed out.

**Interpretation:** Rejection is the dominant exception, representing 83.16% of non-delivered outcomes.

**Business significance:** Rejection prevention offers the largest opportunity within the exception pool.

**Limitations:** `Picked up` may reflect a different fulfillment path rather than a failed order.

## Financial Analysis

### 16. What is the delivered-order financial summary?

**SQL result**

| Delivered orders | Bill subtotal | Packaging charges | Delivered order value | Average order value |
|---:|---:|---:|---:|---:|
| 21,131 | 15,847,306.96 | 688,097.46 | 14,423,379.76 | 682.57 |

**Interpretation:** Delivered final order value is lower than subtotal plus packaging charges because recorded discounts and other pricing components affect the final total.

**Business significance:** The comparison provides a high-level view of gross basket value, charges, and final customer order value.

**Limitations:** Source fields may not form a complete accounting reconciliation, and currency is not explicitly documented.

### 17. How much discount value is recorded by type?

**SQL result**

| Restaurant promo | Restaurant flat-off | Gold | Brand pack | Total recorded discount |
|---:|---:|---:|---:|---:|
| 1,374,488.83 | 671,098.44 | 2,057.50 | 64,380.07 | 2,112,024.84 |

**Interpretation:** Restaurant-funded promo discounts are the largest recorded discount component, accounting for 65.08% of total recorded discounts.

**Business significance:** Promotion effectiveness and funding strategy should focus first on restaurant promo and flat-off programs.

**Limitations:** The analysis measures discount amount, not incremental demand, profitability, or causal campaign lift.

### 18. Which subzones generate the highest delivered order value?

**SQL result**

| Subzone | Delivered orders | Delivered order value | Average value |
|---|---:|---:|---:|
| Greater Kailash 2 (GK2) | 7,311 | 4,711,863.25 | 644.49 |
| Sector 4 | 6,463 | 4,452,499.52 | 688.92 |
| DLF Phase 1 | 3,653 | 2,574,525.45 | 704.77 |
| Sector 135 | 2,426 | 1,747,018.46 | 720.12 |
| Vasant Kunj | 916 | 687,580.04 | 750.63 |
| Shahdara | 359 | 248,502.42 | 692.21 |
| Chittaranjan Park | 2 | 949.62 | 474.81 |
| Sikandarpur | 1 | 441.00 | 441.00 |

**Interpretation:** Greater Kailash 2 contributes the most delivered order value due to its high order volume, while Vasant Kunj has the highest average among subzones with meaningful volume.

**Business significance:** Market planning should distinguish total market contribution from average basket size.

**Limitations:** Very small subzone samples are not reliable for comparison, and results do not control for outlet count or operating period.

## Customer Satisfaction

### 19. What is the overall submitted customer rating?

**SQL result:** 2,491 orders were rated, producing an 11.68% completion rate and an average submitted rating of 4.36 out of 5.

**Interpretation:** Submitted ratings are favorable, but nearly nine in ten orders have no rating.

**Business significance:** The positive average is encouraging, while increasing feedback coverage would improve confidence in satisfaction monitoring.

**Limitations:** Ratings are voluntary and may be affected by response bias; the result does not represent every customer.

### 20. How are submitted ratings distributed?

**SQL result**

| Rating | Rated orders | Share of ratings |
|---:|---:|---:|
| 5 | 1,728 | 69.37% |
| 4 | 360 | 14.45% |
| 3 | 144 | 5.78% |
| 2 | 82 | 3.29% |
| 1 | 177 | 7.11% |

**Interpretation:** 83.82% of submitted ratings are four or five stars, although one-star ratings are more common than two-star ratings.

**Business significance:** The one-star segment is a focused pool for root-cause review despite the strong overall score.

**Limitations:** Only submitted ratings are included, so the distribution is subject to selection bias.

### 21. Which complaint categories are reported most often?

**SQL result**

| Complaint category | Count |
|---|---:|
| Non-refunded complaint | 157 |
| Poor taste or quality | 120 |
| Poor packaging or spillage | 104 |
| Wrong item(s) delivered | 48 |
| Item(s) missing or not delivered | 40 |

**Interpretation:** Non-refunded complaints are the most frequent recorded category, followed by food quality and packaging issues.

**Business significance:** Refund resolution, product quality, and packaging are the highest-priority recorded complaint themes.

**Limitations:** Only 469 orders have a complaint tag. Missing tags do not prove that no issue occurred, and counts do not reflect severity.

## Overall Business Conclusions

- Delivery execution is strong at 99.11%, with rejections representing the clearest exception-reduction opportunity.
- Demand and delivered order value are concentrated in Aura Pizzas and Swaad, especially a small number of high-volume outlets.
- Demand peaks on Saturday and around 8 PM, giving operations a clear staffing and readiness window.
- One-third of customers are repeat customers, leaving a sizable retention opportunity among one-time customers.
- Incorrect or missed order-ready marking affects 10.48% of orders and is a practical handoff improvement area.
- Submitted feedback is positive but sparse; conclusions about satisfaction should remain cautious.
