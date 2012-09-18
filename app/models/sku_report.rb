class SkuReport < Report
  # Generates an array of hashes, each entry representing a days volume/value.
  #
  # @param [Integer, String] id
  # @param Hash
  #
  # @return Array<Hash>
  def self.series(id, range)
    result = select_all_by_range(SERIES, range, :column => 'os.created_at', :id => id)
    values = Hash[result.map {|v| [v['day'], v]}]
    range[:days].map {|d| values[d] || {'day' => d, 'value' => 0, 'volume' => 0}}
  end

  # Generates an array of hashes, each entry representing a days volume/value.
  #
  # @param [Integer, String] id
  # @param Hash
  #
  # @return Array<Hash>
  def self.aggregates(id, range)
    select_all_by_range(AGGREGATES, range, :column => 'os.created_at', :id => id).first
  end

  SERIES = %{
    SELECT SUM(ois.total) AS value, SUM(ois.quantity) AS volume, day
    FROM (
      SELECT
        ois.total, ois.quantity,
        REGEXP_REPLACE(TO_CHAR(os.created_at, 'DD/MM/YYYY'), '0(.)\\/', E'\\\\1\/', 'g') AS day
      FROM order_items AS ois
      JOIN orders AS os ON os.id = ois.order_id
      WHERE ois.sku_id = :id AND is_revenue(os.status) AND :current
    ) AS ois
    GROUP BY day
  }.freeze

  AGGREGATES = %{
    WITH ois AS (
      SELECT
        ois.total,
        ois.quantity,
        DATE_TRUNC('day', os.created_at) AS day,
        DATE_TRUNC('month', os.created_at) AS month
      FROM order_items AS ois
      JOIN orders AS os ON os.id = ois.order_id AND is_revenue(os.status) AND :current
      WHERE ois.sku_id = :id
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
end
