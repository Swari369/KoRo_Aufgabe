# KoRo Data Science Internship — SQL Assessment

**Submitted by:** Swari Tamboli · swari.tamboli@gmail.com
**Date:** March 18, 2026
**Stack:** BigQuery SQL · Python 3 (pandas, matplotlib, seaborn)

---

## Overview

This repository contains the full solution to the KoRo Data Analytics Working Student SQL Assessment. The assessment covers three tasks: analysing new customer behaviour over time, ranking product popularity by country, and visualising the key findings.

---

## Repository Structure

```
├── Koro task results/
│   ├── Task1.sql              # Task 1 — Customer order activity & new customer share
│   ├── Task1_Bonus.sql        # Task 1 Bonus — Breakdown by reporting channel
│   ├── Task2.sql              # Task 2 — Product popularity by country
│   └── visualisation.ipynb   # Task 3 — All charts (matplotlib / seaborn)
│
├── Koro Task Docs/
│   ├── orders.csv             # Raw order data
│   ├── marketing_sources.csv  # Marketing channel attribution
│   ├── product_locale.csv     # Localised product names
│   └── product_universal.csv  # Universal product categories
│
├── chart1_new_customer_trend.png     # Daily % of new customers over time
├── chart2_category_by_country.png    # Category order volume by country
├── chart3_IT_top5.png                # Italy — Top 5 best-selling products
├── chart4_IT_bottom5.png             # Italy — Bottom 5 least popular products
├── chart5_NL_top5.png                # Netherlands — Top 5 best-selling products
├── chart6_NL_bottom5.png             # Netherlands — Bottom 5 least popular products
└── README.md
```

---

## Dataset

All queries target the `koRo_Aufgabe` BigQuery dataset, which contains four tables:

| Table | Description | Key Columns |
|---|---|---|
| `orders` | Individual order records | order_id, customer_id, order_date, product_number, country_iso |
| `marketing_sources` | Marketing channel attribution | order_id, country_iso, reporting_channel, utm_campaign |
| `product_locale` | Localised product names | sku, product_name, locale |
| `product_universal` | Universal product categories | sku, main_category |

---

## Task 1 — Customer Order Activity & New Customer Share Over Time

**File:** `Koro task results/Task1.sql`

**Objective:** Identify each customer's first order date, measure early repeat activity, and compute the daily share of orders that come from first-time buyers.

**Approach:** Three CTEs — `customer_order_ranked` uses `ROW_NUMBER()` partitioned by `customer_id` to tag each customer's first order; `first_orders` isolates those rows; `customer_activity` joins all orders back to their first-order date and flags whether each order is the customer's first. The final `SELECT` aggregates by `order_date`.

**Output columns:**

| Column | Description |
|---|---|
| `order_date` | Date of orders |
| `total_orders` | Total orders on that date |
| `new_customer_orders` | Orders that were a customer's first ever |
| `new_customer_pct` | `new_customer_orders / total_orders × 100` |
| `repeat_orders_d10` | Repeat orders within 10 days of first order |
| `repeat_orders_d15` | Repeat orders within 15 days of first order |
| `repeat_orders_d20` | Repeat orders within 20 days of first order |

**Key design decisions:**
- `ROW_NUMBER()` (not `RANK`) guarantees exactly one row with rank 1 per customer, even for same-day orders.
- `SAFE_DIVIDE` prevents division-by-zero errors.
- NULLs in `order_date` and `customer_id` are filtered in the first CTE to keep downstream logic clean.
- Repeat windows use `BETWEEN 1 AND N` to exclude day 0 (the first order itself).

---

## Task 1 (Bonus) — Channel Breakdown by Reporting Channel

**File:** `Koro task results/Task1_Bonus.sql`

**Objective:** Add a `reporting_channel` dimension to understand which acquisition channels drive the most new customers.

**Approach:** Extends the Task 1 logic with a `LEFT JOIN` to `marketing_sources`. Because one order can map to multiple channels (one-to-many relationship), a `DISTINCT` sub-select is used before joining to prevent row multiplication. Orders with no attribution are labelled `'Unknown'` via `COALESCE`.

---

## Task 2 — Product Popularity by Country

**File:** `Koro task results/Task2.sql`

**Objective:** Identify the top 5 most ordered and bottom 5 least ordered products for each country, with category-level context.

**Approach:** Three CTEs — `order_product` joins `orders` to `product_universal` to enrich each order with `main_category`; `product_summary` aggregates to `(country_iso, sku, main_category)` level using `COUNT(DISTINCT order_id)`; `product_ranked` applies `DENSE_RANK()` in both ascending and descending order of `total_orders`. The final `SELECT` filters with `rank_top <= 5 OR rank_bottom <= 5`.

**Key design decisions:**
- `DENSE_RANK()` over `RANK()` so tied products share the same rank position.
- `COUNT(DISTINCT order_id)` avoids double-counting.
- `WHERE main_category IS NOT NULL` excludes SKUs not present in `product_universal`.

---

## Task 3 — Data Visualisations

**File:** `Koro task results/visualisation.ipynb`

Six charts were produced using Python (pandas + matplotlib + seaborn):

| Chart | File | Type | Insight |
|---|---|---|---|
| Daily % New Customers | `chart1_new_customer_trend.png` | Line chart | Tracks acquisition momentum over time |
| Category Volume by Country | `chart2_category_by_country.png` | Grouped bar chart | Compares category demand across IT and NL |
| Italy Top 5 | `chart3_IT_top5.png` | Horizontal bar chart | Best-selling SKUs in Italy |
| Italy Bottom 5 | `chart4_IT_bottom5.png` | Horizontal bar chart | Lowest-demand SKUs in Italy |
| Netherlands Top 5 | `chart5_NL_top5.png` | Horizontal bar chart | Best-selling SKUs in the Netherlands |
| Netherlands Bottom 5 | `chart6_NL_bottom5.png` | Horizontal bar chart | Lowest-demand SKUs in the Netherlands |

---

## How to Run

### SQL (BigQuery)

1. Upload the four CSV files from `Koro Task results/` to a BigQuery dataset named `koRo_Aufgabe`.
2. Run the `.sql` files in order: `Task1.sql` → `Task1_Bonus.sql` → `Task2.sql`.
3. Export results as `Task1_Results.csv` and `Task2_Results.csv` into the working directory.

### Python Visualisations

```bash
pip install pandas matplotlib seaborn
jupyter notebook "Koro task results/visualisation.ipynb"
```

The notebook reads `Task1_Results.csv` and `Task2_Results.csv` and outputs all six chart PNGs.

---

## Key Findings

**New Customer Trends (Task 1):** New customer share starts near 100% on day one — an expected dataset launch effect — and gradually declines to the 60–80% range as returning customers accumulate. Early repeat behaviour within 10–20 days of first purchase is modest, indicating room to improve post-purchase retention flows.

**Product Popularity (Task 2):** Both Italy and the Netherlands show highly concentrated demand at the top, with a long low-demand tail. Category preferences differ meaningfully between the two markets, suggesting localised assortment and marketing strategies would outperform a one-size-fits-all approach.
