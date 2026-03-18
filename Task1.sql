WITH customer_order_ranked AS (
  SELECT
    order_id,
    customer_id,
    order_date,
    product_number,
    country_iso,
    ROW_NUMBER() OVER (
      PARTITION BY customer_id
      ORDER BY order_date ASC
    ) AS order_rank
  FROM `koRo_Aufgabe.orders`
  WHERE order_date IS NOT NULL
    AND customer_id IS NOT NULL
),

first_orders AS (
  SELECT
    customer_id,
    order_date AS first_order_date
  FROM customer_order_ranked
  WHERE order_rank = 1
),

customer_activity AS (
  SELECT
    o.order_id,
    o.customer_id,
    o.order_date,
    o.product_number,
    o.country_iso,
    f.first_order_date,
    DATE_DIFF(o.order_date, f.first_order_date, DAY) AS days_since_first_order,
    CASE WHEN DATE_DIFF(o.order_date, f.first_order_date, DAY) = 0 THEN 1 ELSE 0 END AS is_first_order
  FROM `koRo_Aufgabe.orders` o
  JOIN first_orders f USING (customer_id)
  WHERE o.order_date IS NOT NULL
)

SELECT
  order_date,
  COUNT(order_id)                                                AS total_orders,
  SUM(is_first_order)                                            AS new_customer_orders,
  ROUND(
    SAFE_DIVIDE(SUM(is_first_order), COUNT(order_id)) * 100, 2
  )                                                              AS new_customer_pct,

  -- Early repeat activity columns (per-date aggregated view)
  COUNTIF(days_since_first_order BETWEEN 1 AND 10)               AS repeat_orders_d10,
  COUNTIF(days_since_first_order BETWEEN 1 AND 15)               AS repeat_orders_d15,
  COUNTIF(days_since_first_order BETWEEN 1 AND 20)               AS repeat_orders_d20

FROM customer_activity
GROUP BY order_date
ORDER BY order_date;
