class ProductReport < Report
  # Counts the total number of SKUs sold. Only includes orders that actually
  # generated revenue.
  #
  # @return Integer
  def self.total_volume
    Sku.count_by_sql(TOTAL_VOLUME)
  end

  # Generates a hash containing summaries of products and skus, grouped by
  # product.
  #
  # @return Hash
  def self.listing
    skus = Sku.find_by_sql(SKU_SUMMARY).group_by(&:product_id)
    Product.find_by_sql(PRODUCT_SUMMARY).map do |product|
      {:product => product, :skus => skus[product.id] || []}
    end
  end

  TOTAL_VOLUME = %{
    SELECT COALESCE(SUM(ois.quantity), 0)
    FROM order_items AS ois
    JOIN orders AS os ON is_revenue(os.status) AND os.id = ois.order_id
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
      ps.id, ps.slug, ps.name,
      ois.volume, ois.revenue
    FROM (
      SELECT * FROM sales
      UNION ALL
      SELECT id, NULL, NULL FROM products WHERE id NOT IN (SELECT product_id FROM sales)
    ) AS ois
    JOIN products AS ps ON ps.id = ois.product_id;
  }.freeze

  SKU_SUMMARY = %{
    WITH sales AS (
      SELECT ois.sku_id, SUM(ois.quantity) AS volume, SUM(ois.total) AS revenue
      FROM order_items AS ois
      JOIN orders AS os ON is_revenue(os.status) AND os.id = ois.order_id
      GROUP BY ois.sku_id
    )

    SELECT skus.product_id, skus.id, ois.volume, ois.revenue
    FROM (
      SELECT * FROM sales
      UNION ALL
      SELECT id, NULL, NULL FROM skus WHERE id NOT IN (SELECT sku_id FROM sales)
    ) AS ois
    JOIN skus ON skus.id = ois.sku_id
  }.freeze
end
