-- marketing_sources has one-to-many with orders (multi-channel attribution)

WITH customer_order_ranked AS (
  SELECT
    order_id,
    customer_id,
    order_date,
    country_iso,
    ROW_NUMBER() OVER (
      PARTITION BY customer_id
      ORDER BY order_date ASC
    ) AS order_rank
  FROM `koRo_Aufgabe.orders`
  WHERE order_date IS NOT NULL AND customer_id IS NOT NULL
),

first_orders AS (
  SELECT customer_id, order_date AS first_order_date
  FROM customer_order_ranked
  WHERE order_rank = 1
),

customer_activity AS (
  SELECT
    o.order_id,
    o.customer_id,
    o.order_date,
    o.country_iso,
    f.first_order_date,
    DATE_DIFF(o.order_date, f.first_order_date, DAY) AS days_since_first_order,
    CASE WHEN DATE_DIFF(o.order_date, f.first_order_date, DAY) = 0 THEN 1 ELSE 0 END AS is_first_order
  FROM `koRo_Aufgabe.orders` o
  JOIN first_orders f USING (customer_id)
  WHERE o.order_date IS NOT NULL
),

-- Join marketing_sources; one order may have multiple channels → explode intentionally
activity_with_channel AS (
  SELECT
    ca.*,
    COALESCE(ms.reporting_channel, 'Unknown') AS reporting_channel
  FROM customer_activity ca
  -- LEFT JOIN keeps orders with no marketing attribution
  LEFT JOIN (
    SELECT DISTINCT order_id, reporting_channel
    FROM `koRo_Aufgabe.marketing_sources`
    WHERE reporting_channel IS NOT NULL
  ) ms ON ca.order_id = ms.order_id
)

SELECT
  order_date,
  reporting_channel,
  COUNT(order_id)                                                 AS total_orders,
  SUM(is_first_order)                                             AS new_customer_orders,
  ROUND(
    SAFE_DIVIDE(SUM(is_first_order), COUNT(order_id)) * 100, 2
  )                                                               AS new_customer_pct
FROM activity_with_channel
GROUP BY order_date, reporting_channel
ORDER BY order_date, reporting_channel;
