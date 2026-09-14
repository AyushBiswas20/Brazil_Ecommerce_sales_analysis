# Olist E-Commerce Analysis

**By Ayush Biswas**

This is my end-to-end data analysis project. I took a real dataset of a Brazilian online marketplace (Olist, from Kaggle), loaded it into a database, asked it 18 business questions in SQL, then went deeper with Python, and finally wrote up the results like a real analyst would for a CEO.

The dataset is big and messy: about 100,000 orders spread across 9 connected tables, covering late 2016 to 2018. Working with it taught me more than any tutorial ever did, because real data has real problems, and I have documented all of them.

## The questions I tried to answer

I imagined a CEO walking up to me with these questions:

1. How is revenue doing? Is the business growing?
2. Where does the money come from (states, categories, sellers)?
3. Are deliveries on time, and does being late cost us anything?
4. Are customers happy?
5. Do customers come back, or do we buy once and never see them again?
6. What should the company actually do next?

## Tools I used

- MySQL as the main database (I also kept a SQLite backup, and I am glad I did)
- Python (pandas) to load the CSVs into the database and to verify the loads
- SQL (MySQL Workbench) for the 18 business questions
- pandas and matplotlib/seaborn in Jupyter for charts, RFM segmentation and cohort analysis
- One executive memo at the end, because numbers mean nothing if nobody acts on them

## What I found (the short version)

- Total delivered revenue: R$13.22 million. Revenue grew roughly 8 times during 2017, peaked in November 2017 (Black Friday, which I confirmed three different ways), then plateaued in 2018.
- The business lives in the southeast: Sao Paulo, Rio and Minas Gerais together bring 63.4% of revenue. Sao Paulo alone brings 38.3%.
- Delivery is on time 91.89% of the time, but late orders get punished hard: they average 2.57 stars against 4.29 stars for on-time orders. That is a 1.7 star trust penalty.
- Customers almost never come back. Only about 3.4% ever order again, and monthly cohort retention after the first month is around 0.5%. Only 1,241 customers out of 93,358 qualify as true Champions.
- Money is very concentrated: 16% of customers (Big Spenders) generate 49% of all revenue.
- One warning sign I liked finding: bed_bath_table is our 3rd biggest category by revenue but also sits in the bottom 10 by review score. We sell a lot of something people are not happy with.

## The charts

All charts were produced in Jupyter from queries against my MySQL database. They are in the `images` folder:

- Monthly revenue line (takeoff, peak, plateau)
- Revenue by state (the Sao Paulo cliff)
- On-time vs late review scores (the 1.7 star gap)
- Payment types (3 out of 4 payments are credit card)
- Review score distribution (love it or hate it: people give 5 or 1, rarely in between)
- RFM customer segments
- Revenue per segment
- Cohort retention heatmap

## What is in this repository

- `PROJECT_JOURNAL.md` — my working log: every data quality problem I found, how I investigated it, what I decided, and what I learned. If you only read one file, read this one.
- `memo/EXECUTIVE_MEMO.pdf` — a one page memo for the CEO: findings and four recommendations.
- `sql/key_queries.sql` — the important SQL queries with the business question written above each one.
- `src/` — the Python scripts I used to load CSVs into MySQL and verify the row counts.
- `images/` — all the charts.

## How to run it

1. Download the Olist dataset from Kaggle (search "olistbr/brazilian-ecommerce").
2. In `src/load_to_mysql.py`, set your MySQL password and the folder where you put the CSVs. Keep the password on your machine, do not commit it.
3. Run the loader. It prints a verification table that compares loaded row counts against expected counts, because I do not trust a load until I have counted.
4. Open `sql/key_queries.sql` in MySQL Workbench and run the queries against the `olist` schema.
5. The notebook part needs pandas, matplotlib, seaborn, sqlalchemy and pymysql.

## The honest parts

A few things went wrong and I kept the record of all of them, because that is where the real learning is:

- Kaggle's published row counts were wrong for two tables. One reason: hundreds of review comments contain hidden line breaks, so counting lines instead of records overcounts by thousands. I caught it because my verification table refused to say OK.
- I once flipped a comparison operator in an on-time/late query and very confidently produced a completely upside-down result. My sniff test caught it (a marketplace where 92% of deliveries are late does not grow 8x in a year). I now one-row-test every CASE WHEN I write.
- I tried to declare a foreign key on a column that has duplicates, learned the difference between declared constraints and real joins, and built a cleaned geolocation table to fix the fan-out problem.

## What is next

A Power BI dashboard on top of the same MySQL database, and some review text mining (the Portuguese comments).

Ayush Biswas
