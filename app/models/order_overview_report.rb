class OrderOverviewReport < Report
  # Creates a list of the top ten SKUs by both revenue and by volume.
  #
  # @param Hash range
  #
  # @return Hash<Array>
  def self.top_ten(range)
      [:revenue, :volume].inject({}) do |acc, col|
        results = select_all_by_range(TOP_TEN % [col, col, col], range, :column => 'os.created_at', :previous_column => 'os.created_at')
        acc[col] = results.map {|r| TopTenDecorator.new(r)}
        acc
      end
  end

  # Calculates the revenue, order and sku volume over the month.
  #
  # @param Hash range
  #
  # @return Array<Hash>
  def self.series(range)
    values = Hash[select_all_by_range(SERIES, range, :column => 'os.created_at').map {|v| [v['day'], v]}]
    range[:days].map {|d| values[d] || {'day' => d, 'value' => 0, 'volume' => 0, 'sku_volume' => 0}}
  end

  # Returns a hash, where each key is a different aggregate value e.g. average_value
  # revenue etc.
  #
  # @param Hash range
  #
  # @return Hash
  def self.aggregates(range)
    OrderAggregateDecorator.new(select_all_by_range(AGGREGATES, range, :column => 'month').first || {})
  end

  # Generates totals for orders across all time.
  #
  # @return Hash
  def self.grand_totals
    select_all(GRAND_TOTALS).first || {}
  end

  TOP_TEN = %{
    WITH previous AS (
      SELECT *, ROW_NUMBER() OVER(ORDER BY %s DESC) AS position
      FROM (
        SELECT sku_id, SUM(ois.total) AS revenue, COUNT(ois) AS volume
        FROM (
          SELECT ois.sku_id, ois.quantity, ois.total
          FROM orders AS os
          JOIN order_items AS ois ON ois.order_id = os.id
          WHERE :previous AND is_revenue(os.status)
        ) AS ois
        GROUP BY sku_id
      ) AS ois
    ),
    current AS (
      SELECT *, ROW_NUMBER() OVER(ORDER BY %s DESC) AS position
      FROM (
        SELECT sku_id, SUM(ois.total) AS revenue, COUNT(ois) AS volume
        FROM (
          SELECT ois.sku_id, ois.quantity, ois.total
          FROM orders AS os
          JOIN order_items AS ois ON ois.order_id = os.id
          WHERE :current AND is_revenue(os.status)
        ) AS ois
        GROUP BY sku_id ORDER BY %s DESC LIMIT 10
      ) AS ois
    )

    SELECT
      chart.*,
      skus.product_id,
      skus.short_desc,
      (SELECT name FROM products AS ps WHERE ps.id = skus.product_id) AS product_name,
      ABS(chart.position - previous_position) AS shift,
      CASE
        WHEN previous_position > 10 THEN 'new'
        WHEN chart.position = previous_position THEN 'none'
        WHEN chart.position < previous_position THEN 'up'
        WHEN chart.position > previous_position THEN 'down'
        ELSE 'new'
      END AS dir
    FROM (
      SELECT
        current.*,
        previous.position AS previous_position,
        previous.revenue AS previous_revenue,
        previous.volume AS previous_volume
      FROM current
      LEFT JOIN previous ON previous.sku_id = current.sku_id
    ) AS chart
    JOIN skus ON skus.id = sku_id
    ORDER BY position ASC
  }.freeze

  SERIES = %{
    SELECT
      SUM(os.total) AS value,
      COUNT(os.*) AS volume,
      SUM(sku_volume) AS sku_volume,
      os.day
    FROM (
      SELECT
        total,
        (SELECT SUM(quantity) FROM order_items WHERE order_id = os.id) AS sku_volume,
        REGEXP_REPLACE(TO_CHAR(os.created_at, 'DD/MM/YYYY'), '0(.)\\/', E'\\\\1\/', 'g') AS day
      FROM orders AS os
      WHERE is_revenue(os.status) AND :current
    ) AS os
    GROUP BY os.day
    }.freeze

  AGGREGATES = %{
    WITH totals AS (
      SELECT
        os.month,
        COUNT(os.*) AS volume,
        COALESCE(SUM(os.total), 0) AS revenue,
        COALESCE(SUM(os.total) / COUNT(os.*), 0) AS average_value
      FROM (
        SELECT DATE_TRUNC('month', created_at) AS month, total
        FROM orders WHERE is_revenue(status)
      ) AS os
      GROUP BY month
    ),
    best_by_volume AS (
     SELECT month, volume FROM totals ORDER BY volume DESC LIMIT 1
    ),
    best_by_revenue AS (
     SELECT month, revenue FROM totals ORDER BY revenue DESC LIMIT 1
    ),
    best_by_average AS (
      SELECT month, average_value FROM totals ORDER BY average_value DESC LIMIT 1
    ),
    previous AS (
      SELECT * FROM totals WHERE :previous
    )

    SELECT
      *,
      movement_dir(os.this_volume, os.previous_volume) AS volume_movement,
      movement_dir(os.this_revenue, os.previous_revenue) AS revenue_movement,
      movement_dir(os.this_average_value, os.previous_average_value) AS average_value_movement,
      (SELECT volume FROM best_by_volume) AS best_volume,
      (SELECT month FROM best_by_volume) AS best_volume_month,
      (SELECT revenue FROM best_by_revenue) AS best_revenue,
      (SELECT month FROM best_by_revenue) AS best_revenue_month,
      (SELECT average_value FROM best_by_average) AS best_average_value,
      (SELECT month FROM best_by_average) AS best_average_value_month,
      (SELECT SUM(volume) FROM totals) AS total_volume,
      (SELECT SUM(revenue) FROM totals) AS total_revenue,
      (SELECT SUM(revenue) / SUM(volume) FROM totals) AS average_revenue,
      (SELECT SUM(volume) / COUNT(totals.*) FROM totals)::integer AS average_volume,
      (SELECT SUM(total) / COUNT(orders) FROM orders WHERE is_revenue(status)) AS average_average_value,
      (SELECT created_at FROM orders WHERE is_revenue(status) ORDER BY created_at ASC LIMIT 1) AS first_order
    FROM (
      SELECT
        month AS this_month,
        volume AS this_volume,
        revenue AS this_revenue,
        average_value AS this_average_value,
        (SELECT volume FROM previous) AS previous_volume,
        (SELECT revenue FROM previous) AS previous_revenue,
        (SELECT average_value FROM previous) AS previous_average_value
      FROM totals
      WHERE :current
    ) AS os
  }.freeze

  GRAND_TOTALS = %{
    WITH os AS (
      SELECT
        os.total,
        (SELECT SUM(quantity) FROM order_items WHERE order_id = os.id) AS quantity,
        DATE_TRUNC('day', os.created_at) AS day,
        DATE_TRUNC('month', os.created_at) AS month
      FROM orders AS os
      WHERE is_revenue(status)
    ),
    revenue_month AS (
      SELECT SUM(total) AS revenue, month
      FROM os GROUP BY month ORDER BY revenue DESC LIMIT 1
    ),
    revenue_day AS (
      SELECT SUM(total) AS revenue, day
      FROM os GROUP BY day ORDER BY revenue DESC LIMIT 1
    ),
    volume_month AS (
      SELECT SUM(quantity) AS volume, month
      FROM os GROUP BY month ORDER BY volume DESC LIMIT 1
    ),
    volume_day AS (
      SELECT SUM(quantity) AS volume, day
      FROM os GROUP BY day ORDER BY volume DESC LIMIT 1
    )

    SELECT
      (SELECT SUM(total) FROM os) AS total_value,
      (SELECT SUM(quantity) FROM os) AS total_volume,
      (SELECT SUM(total) / SUM(quantity) FROM os) AS average_order_value,
      (SELECT revenue FROM revenue_month) AS best_month_revenue,
      (SELECT month FROM revenue_month) AS best_month_for_revenue,
      (SELECT volume FROM volume_month) AS best_month_volume,
      (SELECT month FROM volume_month) AS best_month_for_volume,
      (SELECT revenue FROM revenue_day) AS best_day_revenue,
      (SELECT day FROM revenue_day) AS best_day_for_revenue,
      (SELECT volume FROM volume_day) AS best_day_volume,
      (SELECT day FROM volume_day) AS best_day_for_volume
  }.freeze
end
