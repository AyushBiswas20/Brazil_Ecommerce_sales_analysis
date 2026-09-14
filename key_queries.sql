USE olist;

#Question 1 — "How big is my shop?" (counting)
SELECT COUNT(*) AS total_orders   FROM olist_orders;
SELECT COUNT(*) AS total_sellers  FROM olist_sellers;
SELECT COUNT(*) AS total_products FROM olist_products;

#Question 2 "How many REAL people are my customers?"
select count(*) as Total ,
count(distinct customer_unique_id ) as unique_cust
from olist_customers;
# Repeat customer 
select (count(*) - count(distinct customer_unique_id)) / count(*)* 100 as Repeat_cust
from olist_customers ;

#Question 3 — "How do my customers pay?"
select payment_type, count(*) as payment_count,
ROUND(AVG(payment_value), 2) AS avg_ticket
from olist_order_payments
group by payment_type ;

#Question 4 — "What share of orders actually arrive?"

SELECT order_status,
       COUNT(*) AS orders,
       ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM olist_orders), 2) AS pct
FROM olist_orders
GROUP BY order_status
ORDER BY orders DESC;

# Question 5 - "how is revenue trending by month?"

SELECT DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS month,
       SUM(oi.price) AS revenue
FROM olist_order_items oi
JOIN olist_orders o
  ON oi.order_id = o.order_id
WHERE o.order_status = 'delivered'
GROUP BY month
ORDER BY month;

#Question 6 - "how is revenue trending by month?"
select DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS month , 
round(SUM(oi.price),2) AS revenue
from olist_orders o 
join olist_order_items oi
on o.order_id = oi.order_id
where o.order_status ="delivered"
GROUP BY month
ORDER BY month;

# Finding - why there is sudden spike in the year of 2017
SELECT DATE(order_purchase_timestamp) AS day, COUNT(*) AS orders
FROM olist_orders
WHERE order_purchase_timestamp >= '2017-11-20'
  AND order_purchase_timestamp <  '2017-11-27'
GROUP BY day
ORDER BY day;

# Question 7 - Top 10 categories by revenue 
select t.product_category_name_english as category,
round(sum(oi.price),2) as revenue ,
COUNT(*) AS items_sold,
round(sum(oi.price)/COUNT(*),2) as $peritem
from olist_order_items oi join
olist_products p
on p.product_id = oi.product_id join product_category_name_translation t
on p.product_category_name = t.product_category_name  
join olist_orders o 
on o.order_id = oi.order_id
where o.order_status = "delivered"
group by t.product_category_name_english 
ORDER BY revenue DESC
LIMIT 10;


# TOTAL sale from the delivered ordered 

select round(sum(price),2) as sales 
from olist_orders o join 
olist_order_items oi on
o.order_id = oi.order_id 
where  o.order_status ='delivered';

#  Question 8 — Which STATES earn the most?
select c.customer_state , round(sum(oi.price),2) as sale ,
COUNT(*) AS items_sold
from olist_orders o join 
olist_order_items oi on
o.order_id = oi.order_id join 
olist_customers c on 
c.customer_id = o.customer_id
where o.order_status = 'delivered'
group by c.customer_state
order by sale desc ; 

# Question 9 — How many DAYS does delivery take?
select c.customer_state , 
round(avg(datediff(o.order_delivered_customer_date,
                          o.order_purchase_timestamp)),1) as avg_days
from olist_orders o 
join olist_customers c 
on o.customer_id = c.customer_id
where o.order_status = 'delivered'
group by c.customer_state
ORDER BY avg_days DESC;

#Question 10 — Do packages arrive ON TIME?
select 
case when o.order_delivered_customer_date <= o.order_estimated_delivery_date
 THEN 'on_time_or_early'
        ELSE 'late'
    END AS verdict,
     COUNT(*) AS orders
FROM olist_orders o
WHERE o.order_status = 'delivered'
GROUP BY verdict;

#Question 11 — THE HEADLINE: do late orders get punished? 

select case when  
o.order_delivered_customer_date <= o.order_estimated_delivery_date
then 'on_time_or_early' else 
'late' end as verdict , 
count(*) as orders,
round(avg(r.review_score),2) as  avg_review_score
from olist_orders o join 
olist_order_reviews r on 
o.order_id = r.order_id
where o.order_status = 'delivered'
group by verdict;


# wrong avg 
select round(avg(price)) from olist_order_items ;
# correct avg
SELECT ROUND(AVG(order_value), 2) AS correct_aov
FROM (
    SELECT oi.order_id, SUM(oi.price) AS order_value
    FROM olist_order_items oi
    JOIN olist_orders o ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY oi.order_id
) AS per_order;

#Question 12 — The AOV Trap: our old enemy, defeated by YOU this time 

with monthly as (
select date_format(o.order_purchase_timestamp, '%Y-%m') as months,
round(sum(oi.price),1) as revenue 
	FROM olist_order_items oi
    JOIN olist_orders o ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY months)
    select months , revenue,
    lag(revenue) over (order by months) as prev_month_rev,
   round((revenue - lag(revenue) over (order by months))/(lag(revenue) over (order by months))*100,2) as growth_pct
    from monthly;
    
# Question 13 — "By each month, how much has the marketplace earned in its ENTIRE life so far?"    

with monthly as (
select date_format(o.order_purchase_timestamp, '%Y-%m') as months,
sum(oi.price) as revenue 
from olist_order_items oi
    JOIN olist_orders o ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY months)
select months , revenue , 
round(sum(revenue) over (order by months),2) as running_revenue,
round((revenue - lag(revenue) over (order by months))
             / lag(revenue) over (order by months) * 100, 2) as growth_pct
from monthly;

# Question 14 — In EACH state, which product category earns the most?
with state_category as(
select c.customer_state as state,
       t.product_category_name_english AS category,
       SUM(oi.price) AS revenue 
from olist_orders o 
join olist_order_items oi on o.order_id = oi.order_id
join olist_customers c on o.customer_id = c.customer_id
join olist_products p on oi.product_id = p.product_id
join product_category_name_translation t on 
p.product_category_name = t.product_category_name
where o.order_status = 'delivered'
group by c.customer_state , t.product_category_name
), 
ranked as(
select state , category , 
round(revenue, 2) as revenue,
rank() over (partition by state order by revenue desc) as rnk
from state_category )
select state , category , revenue
from ranked
where rnk = 1
ORDER BY revenue DESC;

-- Question 15 — THE COHORT QUESTION (senior-level): "Of the customers who made their FIRST order in a given month —
--       how many ordered again in the following months?"

 WITH person_orders AS (
    select c.customer_unique_id,
    min(o.order_purchase_timestamp) AS first_order_date,
    COUNT(DISTINCT o.order_id)      AS n_orders
    FROM olist_orders o
JOIN olist_customers c ON c.customer_id = o.customer_id
GROUP BY c.customer_unique_id
)
 SELECT DATE_FORMAT(first_order_date, '%Y-%m')      AS cohort_month,
       COUNT(*)                                     AS people_joined,
       SUM(n_orders > 1)                            AS came_back,
       ROUND(SUM(n_orders > 1) / COUNT(*) * 100, 2) AS repeat_pct
FROM person_orders
GROUP BY cohort_month
ORDER BY cohort_month;

# Question 16 -	Worst 10 categories by review score 
select t.product_category_name_english,
round(avg(r.review_score),2) as avg_score,
count(*) as review_count
from  olist_orders o join olist_order_items oi
on o.order_id = oi.order_id join olist_products p 
on oi.product_id = p.product_id join product_category_name_translation t 
on p.product_category_name = t.product_category_name join olist_order_reviews r 
on r.order_id = o.order_id
where o.order_status = 'delivered'
group by t.product_category_name_english
HAVING review_count >= 100
ORDER BY avg_score ASC
limit 10;

# Question 17 - Do installment buyers spend more per order?

with per_order as(
	   SELECT order_id,
       SUM(payment_value) AS order_paid,
       MAX(payment_installments) AS installments
FROM olist_order_payments
GROUP BY order_id
)
select case 
        WHEN installments = 1  THEN 'pay_at_once'
        WHEN installments <= 5 THEN 'few_installments'
        WHEN installments <= 10 THEN 'many_installments'
        ELSE 'extreme_installments'
    END AS installment_bucket,
    count(*) as orders ,
    round(avg(order_paid),2) as avg_order_value   
    from per_order 
    group by installment_bucket
    order by  avg_order_value desc;
    
#Question 18 - Top 10 sellers — rich AND loved?   
 
 select s.seller_id, round(sum(oi.price),2) as revenue,
 count(DISTINCT oi.order_id) as orders, 
 round(avg(r.review_score),2) as n_reviews
 from olist_orders o join olist_order_items oi
 on o.order_id = oi.order_id join olist_order_reviews r 
 on o.order_id = r.order_id join olist_sellers s 
 on s.seller_id = oi.seller_id 
 where o.order_status = 'delivered'
 group by s.seller_id
 HAVING COUNT(DISTINCT oi.order_id) >= 100 
ORDER BY revenue DESC
LIMIT 10;