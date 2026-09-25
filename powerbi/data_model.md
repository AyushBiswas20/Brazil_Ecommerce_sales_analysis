# Data model (star schema)

```
 calender (1)
      |
      v
customers (1) ──────────► ORDERS (*) ◄────────── order_items (*)
      ^                       ^   ^                   |
      |                       |   |                   v
 rfm_customers (1)      payments (*)   reviews (*)   products (1)
 on customer_unique_id                              | 1:1 lookup
                                                  translation
```

## The 7 relationships

| From (1) | To (*) | Join column | Why |
|---|---|---|---|
| olist_orders | olist_order_items | order_id | money lives in items (one order = many items) |
| olist_orders | olist_payments | order_id | one order = up to 3 payment methods |
| olist_orders | olist_order_reviews | order_id | one order = one review (117 orders have none — the join drops them, documented in PROJECT_JOURNAL.md) |
| olist_customers | olist_orders | customer_id | **per-order** customer id (this is the trap — see below) |
| calender | olist_orders | order_purchase_timestamp | time intelligence (calendar built 2016-09-04 → 2018-10-17) |
| olist_customers | rfm_customers | customer_unique_id | person-level snapshot wires through the real person id |
| olist_products | olist_order_items | product_id | category lives on products; money lives on items — the category chart joins through items |

(Plus one 1:1 lookup: `product_category_name_translation` on `olist_products`
[product_category_name] — it is what gives the charts English labels like
`health_beauty` instead of Portuguese. It is a lookup, not a filter, so it never changes counts.)

## The customer-id trap (and the fix)

`olist_customers.customer_id` is issued **per order**, not per person — 99,441 rows.
Real people are `customer_unique_id` — 96,096 rows. Keying anything customer-value related on
`customer_id` gives a 0% repeat rate and nonsense segment math. Every person-level number on
page 3 keys on `customer_unique_id`, which is why the RFM snapshot table exists at all.

## Three deliberate design decisions

1. **One revenue measure, filter inside it.**
   `Revenue = CALCULATE(SUM(price), order_status = "delivered")`. No visual can ever silently
   sum canceled/shipped orders, and no filter pane is needed anywhere.
2. **Text month field, not a date hierarchy.** `Year_month = FORMAT([Date], "yyyy-MM")`.
   It sorts chronologically by itself and avoids Power BI's auto-hierarchy surprises.
3. **RFM computed in Python, imported as a static snapshot.** One row per person (93,358),
   fully auditable, and it keeps the many-to-many person → orders → items math out of the model.

## Why a star schema here

`orders` is the only table where an "event" happened at a single moment — it is the hub fact.
`order_items` hangs off it (the money table). Everything else (customers, payments, reviews,
calendar) filters from the 1 side. All relationships are active, single-direction, and
filtered from the 1 side — no ambiguity, no many-to-many filters, fast visuals.
