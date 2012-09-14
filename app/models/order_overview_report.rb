class OrderOverviewReport < Report
  # Creates a list of the top ten SKUs by both revenue and by volume.
  #
  # @param Hash range
  #
  # @return Hash<Array>
  def self.top_ten(range)
    {
      :revenue  => select_all_by_range(TOP_TEN % %w(revenue revenue), range, 'os.created_at', 'ois.created_at'),
      :volume   => select_all_by_range(TOP_TEN % %w(volume volume), range, 'os.created_at', 'ois.created_at')
    }
  end

  # Calculates the revenue, order and sku volume over the month.
  #
  # @param Hash range
  #
  # @return Array<Hash>
  def self.series(range)
    days = (1..Time.now.month).to_a
    values = Hash[select_all_by_range(SERIES, range, 'os.created_at').map {|v| [v['day'].to_i, v]}]
    days.map {|d| values[d] || {'day' => d, 'value' => 0, 'volume' => '0', 'sku_volume' => 0}}
  end

  # Returns a hash, where each key is a different aggregate value e.g. average_value
  # revenue etc.
  #
  # @param Hash range
  #
  # @return Hash
  def self.aggregates(range)
    select_all_by_range(AGGREGATES, range, 'month').first
  end

  # Generates a query by interpolating the appropriate time predicate functions
  # into the provided string. It then executes the query using #select_all.
  #
  # @param String query
  # @param Hash range
  # @param String col
  # @param String prev_col
  #
  # @return Array<Hash>
  def self.select_all_by_range(query, range, col, prev_col = nil)
    case range[:mode]
    when :month, :none
      if range[:mode] == :none
        now = Time.now
        year = now.year
        month = now.month
      else
        year = range[:year]
        month = range[:month]
      end

      prepared = query.gsub(/(:current|:previous)/) do |match|
        case match
        when ':current'   then "within_month(#{year}, #{month}, #{col})"
        when ':previous'  then "within_previous_month(#{year}, #{month}, #{prev_col || col})"
        end
      end

      select_all(prepared)
    when :range

    end
  end

  TOP_TEN = %{
    WITH previous AS (
      SELECT *, ROW_NUMBER() OVER(ORDER BY revenue DESC) AS position
      FROM (
        SELECT sku_id, SUM(ois.total) AS revenue, COUNT(ois) AS volume
        FROM (
          SELECT ois.sku_id, ois.quantity, ois.total
          FROM orders AS os
          JOIN order_items AS ois ON ois.order_id = os.id
          WHERE :previous
        ) AS ois
        GROUP BY sku_id ORDER BY %s DESC
      ) AS ois
    )

    SELECT
      *,
      position - previous_position AS shift,
      CASE
        WHEN previous_position < 10 THEN 'new'
        WHEN position = previous_position THEN 'none'
        WHEN position < previous_position THEN 'up'
        WHEN position > previous_position THEN 'down'
        ELSE 'new'
      END AS dir
    FROM (
      SELECT
        chart.*,
        skus.volume AS sku_name,
        skus.product_id,
        (SELECT name FROM products AS ps WHERE ps.id = skus.product_id) AS product_name,
        ROW_NUMBER() OVER(ORDER BY chart.revenue DESC) AS position,
      previous.position AS previous_position
      FROM (
        SELECT
          sku_id, SUM(ois.quantity) AS volume, SUM(ois.total) AS revenue
        FROM (
          SELECT ois.sku_id, ois.quantity, ois.total
          FROM orders AS os
          JOIN order_items AS ois ON ois.order_id = os.id
          WHERE :current
        ) AS ois
        GROUP BY sku_id ORDER BY %s DESC LIMIT 10
      ) AS chart
      JOIN skus ON skus.id = chart.sku_id
      LEFT JOIN previous ON previous.sku_id = chart.sku_id
    ) AS chart
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
        DATE_PART('day', os.created_at) AS day
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
      SELECT * FROM totals WHERE within_last('month', month)
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
      (SELECT SUM(total) / COUNT(orders) FROM orders WHERE is_revenue(status)) AS average_value,
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
end
