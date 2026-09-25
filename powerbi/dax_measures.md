# DAX measures & calculated columns (complete catalog)

Every measure in the dashboard, with the **exact result it returns** on the Olist data
(99,441 orders, Sep 2016 – Oct 2018). Each result was verified against an independent
Python/pandas computation of the same fact from the raw CSVs.

## Conventions

- Table names below match the Power BI model: `olist olist_orders`, `olist olist_order_items`,
  `olist olist_customers`, `olist olist_payments`, `olist olist_order_reviews`, `calender`,
  `rfm_customers`.
- One revenue measure carries the status filter **inside it** — no visual relies on a filter pane:

```dax
Revenue = CALCULATE(SUM('olist olist_order_items'[price]),
                    'olist olist_orders'[order_status] = "delivered")
```

## Page 1 — Executive Overview

| Measure / column | DAX | Returns |
|---|---|---|
| Revenue | `CALCULATE(SUM('olist olist_order_items'[price]), 'olist olist_orders'[order_status] = "delivered")` | 13,221,498.11 |
| Delivered orders | `COUNTROWS(FILTER('olist olist_orders', 'olist olist_orders'[order_status] = "delivered"))` | 96,478 |
| Average order value | `DIVIDE([Revenue], [Delivered orders])` | 137.04 |
| Total orders | `COUNTROWS('olist olist_orders')` | 99,441 |
| On-time delivery | `DIVIDE(CALCULATE(COUNTROWS('olist olist_orders'), 'olist olist_orders'[order_delivered_customer_date] <= 'olist olist_orders'[order_estimated_delivery_date], 'olist olist_orders'[order_status] = "delivered"), CALCULATE(COUNTROWS('olist olist_orders'), 'olist olist_orders'[order_status] = "delivered"), "n/a")` | 91.9% |
| Average review | `AVERAGE('olist olist_order_reviews'[review_score])` | 4.09 |
| Black friday 2017 | `CALCULATE([Revenue], 'calender'[Year_month] = "2017-11")` | 987,765.37 |

### Month-over-month (calculated column + measures on `calender`)

| Name | DAX | Returns |
|---|---|---|
| prev_year_month (column) | `FORMAT(EOMONTH([Date], -1), "yyyy-MM")` | previous month per row |
| Revenue prev month | `CALCULATE([Revenue], 'calender'[Year_month] = MAX('calender'[prev_year_month]))` | — |
| Revenue MoM % | `DIVIDE([Revenue] - [Revenue prev month], [Revenue prev month], "n/a")` | format `0.0%`; range −26.5% … +109.5% |

`Year_month` (column on `calender`) = `FORMAT([Date], "yyyy-MM")` — deliberately a **text**
field so the axis sorts chronologically by itself, no date hierarchy needed.

## Page 2 — Delivery Performance

| Measure / column | DAX | Returns |
|---|---|---|
| Delivery days (column on orders) | `DATEDIFF('olist olist_orders'[order_purchase_timestamp], 'olist olist_orders'[order_delivered_customer_date], DAY)` | calendar-day difference; overall avg 12.5 |
| Late orders | `CALCULATE(COUNTROWS('olist olist_orders'), 'olist olist_orders'[order_status] = "delivered", 'olist olist_orders'[order_delivered_customer_date] > 'olist olist_orders'[order_estimated_delivery_date])` | 7,826 |
| Late share | `DIVIDE([Late orders], [Delivered orders])` | 8.1% |
| SP delivery days | `CALCULATE(AVERAGE('olist olist_orders'[Delivery days]), 'olist olist_customers'[customer_state] = "SP")` | 8.7 |
| RR delivery days | `CALCULATE(AVERAGE('olist olist_orders'[Delivery days]), 'olist olist_customers'[customer_state] = "RR")` | 29.3 |
| Delivery outcome (column on orders) | `IF(OR('olist olist_orders'[order_status] <> "delivered", 'olist olist_orders'[order_delivered_customer_date] = BLANK()), "Other", IF('olist olist_orders'[order_delivered_customer_date] <= 'olist olist_orders'[order_estimated_delivery_date], "On-time", "Late"))` | On-time / Late / Other (the 1.7★ split comes from filtering reviews through this column) |

## Page 3 — Customer Value

`rfm_customers` is a Python-computed snapshot, one row per real person (93,358 rows),
wired to `olist olist_customers` on `customer_unique_id`. Columns: `segment`, `is_repeat`,
`revenue`, `frequency`, `recency_days`, `last_order_date`, `customer_state`.

| Measure | DAX | Returns |
|---|---|---|
| Customers | `COUNTROWS(rfm_customers)` | 93,358 |
| Repeat rate | `DIVIDE(CALCULATE(COUNTROWS(rfm_customers), rfm_customers[is_repeat] = "Repeat"), COUNTROWS(rfm_customers), "n/a")` | 3.0% |
| Big Spender share | `DIVIDE(CALCULATE(SUM(rfm_customers[revenue]), rfm_customers[segment] = "Big Spender"), SUM(rfm_customers[revenue]))` | 49.5% |
| Champions | `CALCULATE(COUNTROWS(rfm_customers), rfm_customers[segment] = "Champion")` | 1,241 |
| Customers (people, all statuses) | `DISTINCTCOUNT('olist olist_customers'[customer_unique_id])` | 96,096 |

RFM segmentation logic (applied in priority order, T0 = 2018-08-29, last delivered order in
the data): **Champion** = frequency ≥ 2 AND recency ≤ 180d → **Big Spender** = lifetime
revenue ≥ R$ 200 (checked before recency) → **New & Fresh** = recency ≤ 180d →
**Sleeping** = recency ≥ 365d → **Regular** = everything else.
Segment revenues: 6,543,742.80 / 2,593,880.46 / 2,367,048.98 / 1,383,276.23 / 333,549.64 —
they sum to exactly R$ 13,221,498.11 (the grand total), which is the fourth independent
cross-check of the revenue anchor.

## Format codes used

`#,##0` (counts) · `R$ #,##0` (money, whole) · `R$ #,##0.00` (money, exact) ·
`0.0%` (percentages) · `0.00` (days, stars) · `0.0` (ratios)
