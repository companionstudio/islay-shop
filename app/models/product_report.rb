class ProductReport < Report
  # Generates a series of totals for the specified product.
  #
  # @param Integer id
  # @param Hash range
  #
  # @return Array<Hash>
  def self.product_series(id, range)
    result = select_all_by_range(PRODUCT_SERIES, range, :column => 'os.created_at', :id => id)
    values = Hash[result.map {|v| [v['day'], v]}]
    range[:days].map {|d| values[d] || {'day' => d, 'value' => 0, 'volume' => 0}}
  end

  # Calculates various totals for a particular product; vol, revenue etc.
  #
  # @return Hash
  def self.product_aggregates(id, range)
    select_all_by_range(PRODUCT_AGGREGATES, range, :column => 'os.created_at', :id => id).first
  end

  def self.product_skus_summary(id, range)
    select_all_by_range(PRODUCT_SKUS_SUMMARY, range, :column => 'created_at', :id => id)
  end

  # Counts the total number of SKUs sold. Only includes orders that actually
  # generated revenue.
  #
  # @return Integer
  def self.total_volume
    Sku.count_by_sql(TOTAL_VOLUME)
  end

  # Summarizes SKUs with calculated volumes and revenues.
  #
  # @return Array<Hash>
  def self.sku_summary
    Sku.find_by_sql(SKU_SUMMARY)
  end

  # Summarizes products with calculated volumes and revenues.
  #
  # @return Array<Hash>
  def self.product_summary
    Product.find_by_sql(PRODUCT_SUMMARY)
  end

  # Creates a summary of categories, with calculated volumes and revenues,
  # sorted by revenue.
  #
  # @return Array<Array<Hash>>
  def self.category_summary
    results = ProductCategory.find_by_sql(CATEGORY_SUMMARY)
    [results.reject {|r| r.is_parent == 't'}, results]
  end

  PRODUCT_SERIES = %{
    SELECT SUM(ois.total) AS value, SUM(ois.quantity) AS volume, day
    FROM (
      SELECT
        ois.total, ois.quantity,
        REGEXP_REPLACE(TO_CHAR(os.created_at, 'DD/MM/YYYY'), '0(.)\\/', E'\\\\1\/', 'g') AS day
      FROM order_items AS ois
      JOIN orders AS os ON os.id = ois.order_id
      WHERE ois.sku_id IN (SELECT id FROM skus WHERE product_id = :id)
      AND is_revenue(os.status) AND :current
    ) AS ois
    GROUP BY day
  }.freeze

  PRODUCT_AGGREGATES = %{
    WITH ois AS (
      SELECT
        ois.total,
        ois.quantity,
        DATE_TRUNC('day', os.created_at) AS day,
        DATE_TRUNC('month', os.created_at) AS month
      FROM order_items AS ois
      JOIN orders AS os ON os.id = ois.order_id AND is_revenue(os.status) AND :current
      WHERE ois.sku_id IN (SELECT id FROM skus WHERE product_id = :id)
    ),
    revenue_day AS (
      SELECT SUM(total) AS revenue, day
      FROM ois GROUP BY day ORDER BY revenue DESC LIMIT 1
    ),
    revenue_month AS (
      SELECT SUM(total) AS revenue, month
      FROM ois GROUP BY month ORDER BY revenue DESC LIMIT 1
    ),
    volume_day AS (
      SELECT SUM(quantity) AS volume, day
      FROM ois GROUP BY day ORDER BY volume DESC LIMIT 1
    ),
    volume_month AS (
      SELECT SUM(quantity) AS volume, month
      FROM ois GROUP BY month ORDER BY volume DESC LIMIT 1
    )

    SELECT
      (SELECT SUM(total) FROM ois)        AS total_value,
      (SELECT SUM(quantity) FROM ois)     AS total_volume,
      (SELECT revenue FROM revenue_day)   AS best_day_revenue,
      (SELECT day FROM revenue_day)       AS best_day_for_revenue,
      (SELECT revenue FROM revenue_month) AS best_month_revenue,
      (SELECT month FROM revenue_month)   AS best_month_for_revenue,
      (SELECT volume FROM volume_day)     AS best_day_volume,
      (SELECT day FROM volume_day)        AS best_day_for_volume,
      (SELECT volume FROM volume_month)   AS best_month_volume,
      (SELECT month FROM volume_month)    AS best_month_for_volume
  }.freeze

  PRODUCT_SKUS_SUMMARY = %{
    SELECT
      skus.id, skus.name, skus.weight, skus.volume, skus.size,
      COALESCE(SUM(ois.total), 0) AS value,
      COALESCE(SUM(ois.quantity), 0) AS quantity
    FROM (SELECT * FROM skus WHERE skus.product_id = :id) AS skus
    LEFT JOIN order_items AS ois ON ois.sku_id = skus.id
    AND EXISTS (SELECT 1 FROM orders WHERE id = ois.order_id AND is_revenue(status) AND :current)
    GROUP BY skus.id, skus.name, skus.weight, skus.volume, skus.size ORDER BY value DESC
  }.freeze

  TOTAL_VOLUME = %{
    SELECT COALESCE(SUM(ois.quantity), 0)
    FROM order_items AS ois
    JOIN orders AS os ON is_revenue(os.status) AND os.id = ois.order_id
  }.freeze

  CATEGORY_SUMMARY = %{
    WITH os AS (
      SELECT
        ps.product_category_id,
        COALESCE(SUM(ois.quantity), 0) AS volume,
        COALESCE(SUM(ois.total), 0) AS revenue
      FROM orders AS os
      JOIN order_items AS ois ON ois.order_id = os.id
      JOIN skus ON skus.id = ois.sku_id
      JOIN products AS ps ON ps.id = skus.product_id
      GROUP BY ps.product_category_id, os.status HAVING is_revenue(os.status)
    )

    SELECT
      pcs.id, pcs.slug, pcs.name,
      CASE
        WHEN ARRAY_LENGTH(child_ids, 1) > 0 THEN true
        ELSE false
      END AS is_parent,
      CASE
        WHEN ARRAY_LENGTH(child_ids, 1) > 0 THEN
          (SELECT COALESCE(SUM(revenue), 0) FROM os WHERE product_category_id = ANY(pcs.child_ids))
        ELSE
          (SELECT revenue FROM os WHERE product_category_id = pcs.id)
      END AS revenue,
      CASE
        WHEN ARRAY_LENGTH(child_ids, 1) > 0 THEN
          (SELECT COALESCE(SUM(volume), 0) FROM os WHERE product_category_id = ANY(pcs.child_ids))
        ELSE
          (SELECT volume FROM os WHERE product_category_id = pcs.id)
      END AS volume
    FROM (
      SELECT
        id, name, slug, path,
        ARRAY(
          SELECT id FROM product_categories AS cpcs
          WHERE cpcs.path <@ (pcs.path || text2ltree(pcs.id::text))
       ) AS child_ids
      FROM product_categories AS pcs
    ) AS pcs
    ORDER BY revenue DESC
  }.freeze

  PRODUCT_SUMMARY = %{
    WITH sales AS (
      SELECT skus.product_id, SUM(ois.quantity) AS volume, SUM(ois.total) AS revenue
      FROM order_items AS ois
      JOIN orders AS os ON is_revenue(os.status) AND os.id = ois.order_id
      JOIN skus ON skus.id = ois.sku_id
      GROUP BY skus.product_id
    )

    SELECT
      ps.id, ps.slug, ps.name, ps.status, ps.published,
      ois.volume, ois.revenue
    FROM (
      SELECT * FROM sales
      UNION ALL
      SELECT id, NULL, NULL FROM products WHERE id NOT IN (SELECT product_id FROM sales)
    ) AS ois
    JOIN products AS ps ON ps.id = ois.product_id
    ORDER BY revenue DESC
  }.freeze

  SKU_SUMMARY = %{
    WITH sales AS (
      SELECT ois.sku_id, SUM(ois.quantity) AS volume, SUM(ois.total) AS revenue
      FROM order_items AS ois
      JOIN orders AS os ON is_revenue(os.status) AND os.id = ois.order_id
      GROUP BY ois.sku_id
    )

    SELECT
      skus.product_id, skus.id, ois.volume, ois.revenue,
      (SELECT name FROM products WHERE id = product_id) AS product_name
    FROM (
      SELECT * FROM sales
      UNION ALL
      SELECT id, NULL, NULL FROM skus WHERE id NOT IN (SELECT sku_id FROM sales)
    ) AS ois
    JOIN skus ON skus.id = ois.sku_id
    ORDER BY revenue DESC
  }.freeze
end
