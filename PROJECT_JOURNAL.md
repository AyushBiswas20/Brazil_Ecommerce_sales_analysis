# Project Journal — Olist E-Commerce Analysis

**Ayush Biswas**

This is my working log for the project. I wrote it as I went, so it reads like the project actually happened, because it did. It has three parts: how I set things up, the data quality problems I ran into (with what I did about them), and the business answers I produced.

## Part 1: Setup

I picked the Olist Brazilian e-commerce dataset from Kaggle: 9 CSV files, about 100,000 orders, spanning September 2016 to August 2018.

- Main database: MySQL, in a schema called `olist`. I also kept a SQLite copy as a backup file.
- I loaded the CSVs with a small Python script (pandas + SQLAlchemy + PyMySQL). The script converts date columns to real dates and, most importantly, verifies row counts after loading. My rule: a load is not done until the counts are checked.
- All analysis queries ran in MySQL Workbench. All charts were made in Jupyter with pandas, matplotlib and seaborn.

The verified row counts: customers 99,441, orders 99,441, order_items 112,650, payments 103,886, reviews 99,224, products 32,951, sellers 3,095, geolocation 1,000,163, category translation 71. Two of these do not match Kaggle's published numbers, and Finding 1 explains why.

## Part 2: Data quality problems (and what I did)

### Finding 1 — the published row counts were wrong

My loader said 99,224 reviews but Kaggle says 100,000. Payments were off by one too. Instead of ignoring it, I investigated. I counted raw text lines in the reviews file (104,719) and separately counted properly parsed records (99,224). The gap: 3,852 review comments contain hidden line breaks inside the text, so one review can span several text lines. Kaggle's number counts lines, not reviews. The payments gap is just an off-by-one in their published count. I corrected my verification baselines and wrote down why. Lesson: never trust a number until you know how it was counted.

### Finding 2 — most orders are delivered, and revenue needs a filter

Order status breaks down as: delivered 97.02%, shipped 1.11%, canceled 0.63%, unavailable 0.61%, plus small leftovers. Decision: every revenue query filters to delivered orders only, and I state this everywhere.

### Finding 3 — the geolocation fan-out trap

I tried to declare a foreign key from customers to the geolocation table and hit duplicates: 1,000,163 rows but only ~19,000 unique zip prefixes. Geolocation is a catalog of map pins, many pins per zip. A test join fanned out far beyond 99,441 rows, which would silently poison any count. Fix: I built `olist_geolocation_clean` with one row per zip (average lat/lng, one city and state name) using GROUP BY. All location joins use the clean table. Lesson: joins match values, constraints only police writes, and clean derived tables are how keys get earned.

### Finding 4 — the coverage gap

The foreign key attempt then failed the other way: some customer zips simply do not exist in geolocation. A LEFT JOIN + IS NULL count showed 157 customers (0.16%) have no pin at all. Tiny gap, so the decision was: leave the relationship undeclared, use LEFT JOIN when location matters, move on. Error messages are clues, not insults.

### Finding 5 — two categories missing from the translation dictionary

My own LEFT JOIN found two Portuguese category names with no English translation: pc_gamer and portateis_cozinha_e_preparadores_de_alimentos (13 products total). Similar labels exist in the dictionary but they are different categories, so I did not merge them. I inserted two translated rows myself and re-ran the orphan query to confirm zero rows left.

### Finding 6 — the not_defined payment type

Three payments have payment_type = not_defined with a 0 average value. Broken records. Excluded from payment behavior analysis and flagged.

### Finding 7 — I caught a bug in my own analysis

This is the one I am oddly proud of. My first on-time query said 91.9% of deliveries are late. The arithmetic was perfect and the conclusion was completely wrong: I had typed >= instead of <= in the CASE WHEN stamp. Two things caught it: my sniff test (a marketplace where 92% of deliveries are late does not grow 8x in a year) and a manual eye-check of five real rows. Corrected result: 91.89% on time. Standing rule since then: every CASE WHEN gets the one-row test before its numbers are trusted.

### Finding 8 — a leftover foreign key blocked a reload

When I re-ran my loader much later, MySQL refused to drop the customers table because of a foreign key I had declared during earlier experiments. Nothing was damaged (the loop died on the first table), and it taught me why analytical databases usually skip constraints: constraints protect live data, bulk loads want to demolish and rebuild. The loader retired as a one-time truck.

## Part 3: Business answers

Revenue. Total delivered revenue is R$13,221,498.11. The monthly trend shows flat launch months in 2016 (December 2016 had R$10.90 of revenue, which is one confused customer), roughly 8x growth during 2017, a peak of R$988K in November 2017, and a plateau through 2018. I proved the November peak is Black Friday by counting daily orders: 1,176 on the 24th against a normal day of about 230.

Concentration. Sao Paulo, Rio de Janeiro and Minas Gerais together are 63.4% of revenue; SP alone is 38.3%. The top 10 of 71 categories carry about 62%. The top seller is only 1.7% of platform revenue, so the business depends on places, not on individual suppliers.

Delivery. Delivery times range from 8.7 days in Sao Paulo to 29.3 days in Roraima, a 3.4x spread, and the slowest states are all in the north. The on-time audit: 91.89% arrive on or before the promised date. And the headline of the whole project: on-time orders average 4.29 stars, late orders average 2.57. Lateness costs 1.7 stars of trust.

A JOIN lesson hiding in that last number: my late-vs-review query covered 96,361 orders, not 96,478, because the inner join to reviews silently drops orders that were never reviewed. Every JOIN decides who gets left out.

Payments. Credit cards are 73.9% of payments; boleto 19%. Voucher payments have tiny baskets (R$66 average vs R$163 for cards). Installments climb with basket size: pay-at-once orders average R$121, orders split into 11+ installments average R$360. I was careful with the interpretation: installments do not cause bigger baskets, big baskets are what make installments necessary.

The AOV trap. The naive average of item prices is R$121. The true average order value is R$137, because most orders contain one item but some contain several, and the order is what the customer actually experiences. I predicted the direction of this gap before computing it, got the direction wrong, and learned more from being wrong than I would have from being right.

Customers. 99,441 customer rows reduce to 96,096 real people (customer_unique_id vs customer_id was my first big identity lesson). Only about 3.4% of order activity comes from repeat buyers. The cohort heatmap makes it visual: after the joining month, monthly retention sits around 0.3 to 0.7 percent. The white triangle in the lower right of that heatmap is months that have not happened yet for younger cohorts, and learning to read missing data was its own small lesson.

RFM segmentation. I gave each of 93,358 customers a report card: recency, frequency, monetary. Median frequency is exactly 1 (as my repeat analysis predicted). Segments: New and Fresh 31,464, Regular 28,776, Sleeping 17,373, Big Spender 14,504, Champion 1,241. The money view flips the story: Big Spenders are 16% of customers but 49% of revenue. The five segment revenue numbers sum to exactly R$13,221,498.11, which matched my earlier total, my fourth cross-verification.

The overlap findings (my favorite kind). bed_bath_table is 3rd in revenue and bottom-10 in satisfaction (3.92 stars over 10,985 reviews). One top-5 seller earns R$186K at 3.35 stars. Things that earn a lot while disappointing people are where competitors will attack first.

Review scores are love-it-or-hate-it: 5 stars is the tallest bar by far, but 1 star beats both 2 and 3 stars. Angry people skip the middle.

## What this project taught me

- Look at data before touching it, and write down what one row is before counting anything.
- Verify every load, every fix, and every clever idea. Counting is the cheapest bug detector.
- A plausible-looking wrong answer is more dangerous than an error message.
- Predict before you run, then check. Being wrong out loud is how intuition gets trained.
- The same concept lives in Excel, SQL and pandas; learning it once means translating it forever.
- Numbers do not close deals. Sentences with numbers in them do.

## Roadmap

Done: MySQL database with verified loads, 18 SQL business questions, 8 documented data quality findings, Python charts, RFM segmentation, cohort heatmap, executive memo.

Next: a Power BI dashboard on the same MySQL database, and review text mining on the Portuguese comments.

Ayush Biswas
