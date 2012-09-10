class ProductReport < Report
  # Counts the total number of SKUs sold. Only includes orders that actually
  # generated revenue.
  #
  # @return Integer
  def self.total_volume
    Sku.count_by_sql(TOTAL_VOLUME)
  end

  def self.sku_summary
    Sku.find_by_sql(SKU_SUMMARY)
  end

  def self.product_summary
    Product.find_by_sql(PRODUCT_SUMMARY)
  end

  def self.category_summary
    ProductCategory.find_by_sql(CATEGORY_SUMMARY)
  end

  TOTAL_VOLUME = %{
    SELECT COALESCE(SUM(ois.quantity), 0)
    FROM order_items AS ois
    JOIN orders AS os ON is_revenue(os.status) AND os.id = ois.order_id
  }.freeze

  CATEGORY_SUMMARY = %{
    SELECT * FROM product_categories
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
