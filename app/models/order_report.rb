class OrderReport < Report
  # Generates an array of hashes, each entry representing a days volume/value.
  #
  # @param [Integer, String] id
  # @param Hash
  #
  # @return Array<Hash>
  def self.aggregates(range)
    OrderAggregateDecorator.new(select_all_by_range(AGGREGATES, range, :column => 'os.created_at').first || {})
  end

  # Generates a list of orders within the specified days.
  #
  # @param Hash range
  #
  # @return Array<Hash>
  def self.orders(range)
    select_all_by_range(ORDERS, range, :column => 'os.created_at')
  end

  AGGREGATES = %{
    WITH os AS (
      SELECT
        (SELECT SUM(quantity) FROM order_items WHERE order_id = os.id) AS quantity,
        os.total,
        DATE_TRUNC('day', os.created_at) AS day,
        DATE_TRUNC('month', os.created_at) AS month
      FROM orders AS os
      WHERE is_revenue(os.status) AND :current
    ),
    revenue_day AS (
      SELECT COALESCE(SUM(total), 0) AS revenue, day
      FROM os GROUP BY day ORDER BY revenue DESC LIMIT 1
    ),
    revenue_month AS (
      SELECT COALESCE(SUM(total), 0) AS revenue, month
      FROM os GROUP BY month ORDER BY revenue DESC LIMIT 1
    ),
    volume_day AS (
      SELECT COALESCE(SUM(quantity), 0) AS volume, day
      FROM os GROUP BY day ORDER BY volume DESC LIMIT 1
    ),
    volume_month AS (
      SELECT COALESCE(SUM(quantity), 0) AS volume, month
      FROM os GROUP BY month ORDER BY volume DESC LIMIT 1
    )

    SELECT
      (SELECT COALESCE(SUM(total), 0) FROM os)    AS total_value,
      (SELECT COALESCE(SUM(quantity), 0) FROM os) AS total_volume,
      (SELECT COALESCE(SUM(total) / COUNT(*), 0) FROM os) AS average_order_value,
      (SELECT revenue FROM revenue_day)                   AS best_day_revenue,
      (SELECT day FROM revenue_day)                       AS best_day_for_revenue,
      (SELECT revenue FROM revenue_month)                 AS best_month_revenue,
      (SELECT month FROM revenue_month)                   AS best_month_for_revenue,
      (SELECT volume FROM volume_day)                     AS best_day_volume,
      (SELECT day FROM volume_day)                        AS best_day_for_volume,
      (SELECT volume FROM volume_month)                   AS best_month_volume,
      (SELECT month FROM volume_month)                    AS best_month_for_volume
  }.freeze

  ORDERS = %{
    SELECT
      os.id, os.reference, os.name, os.created_at, os.total,
      SUM(quantity) AS quantity, ARRAY_TO_STRING(ARRAY_AGG(sku_name), ', ') AS sku_names
    FROM (
      SELECT os.id, os.reference, os.name, os.total, ois.quantity, os.created_at, skus.id AS sku_name
      FROM orders AS os
      JOIN order_items AS ois ON ois.order_id = os.id
      JOIN skus ON skus.id = ois.sku_id
      WHERE is_revenue(os.status) AND :current
    ) AS os
    GROUP BY os.id, os.reference, os.name, os.created_at, os.total
    ORDER BY created_at DESC
  }.freeze
end
