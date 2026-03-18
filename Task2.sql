WITH order_product AS (
  SELECT
    o.order_id,
    o.country_iso,
    o.product_number                        AS sku,
    pu.main_category
  FROM `koRo_Aufgabe.orders` o
  -- Join on product_number = sku to get category
  LEFT JOIN `koRo_Aufgabe.product_universal` pu
    ON o.product_number = pu.sku
  WHERE o.country_iso IS NOT NULL
    AND o.product_number IS NOT NULL
),

category_summary AS (
  SELECT
    country_iso,
    main_category,
    COUNT(DISTINCT order_id)    AS total_orders,   -- unique orders per category
    COUNT(DISTINCT sku)         AS unique_skus      -- distinct products in category
  FROM order_product
  WHERE main_category IS NOT NULL  -- exclude unmatched SKUs
  GROUP BY country_iso, main_category
),

product_summary AS (
  SELECT
    country_iso,
    sku,
    main_category,
    COUNT(DISTINCT order_id)    AS total_orders
  FROM order_product
  WHERE main_category IS NOT NULL
  GROUP BY country_iso, sku, main_category
),

product_ranked AS (
  SELECT
    *,
    -- Top rank: most ordered = rank 1
    DENSE_RANK() OVER (
      PARTITION BY country_iso
      ORDER BY total_orders DESC
    ) AS rank_top,

    -- Bottom rank: least ordered = rank 1
    DENSE_RANK() OVER (
      PARTITION BY country_iso
      ORDER BY total_orders ASC
    ) AS rank_bottom
  FROM product_summary
)

SELECT
  country_iso,
  sku,
  main_category,
  total_orders,
  rank_top,
  rank_bottom,
  CASE
    WHEN rank_top    <= 5 THEN 'Top 5'
    WHEN rank_bottom <= 5 THEN 'Bottom 5'
  END AS popularity_label
FROM product_ranked
WHERE rank_top <= 5 OR rank_bottom <= 5
ORDER BY country_iso, rank_top;




