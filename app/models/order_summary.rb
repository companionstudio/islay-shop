class OrderSummary < ActiveRecord::Base
  self.table_name = 'orders'

  def self.summary
    select(%{
      id, name, updated_at,
      '#' || id::text AS reference,
      'pending' AS status,
      '$' || TRIM(TO_CHAR(total, '99,999,999.99')) AS formatted_total,
      (SELECT name FROM users WHERE id = updater_id) AS updater_name,
      (SELECT ARRAY_TO_STRING(ARRAY_AGG(ps.name::text), ', ')
       FROM order_items AS ois
       JOIN skus ON skus.id = ois.sku_id
       JOIN products AS ps ON ps.id = skus.product_id
       GROUP BY order_id HAVING order_id = orders.id) AS items_summary
    })
  end

  def self.sorted(s)
    if s
      order(s)
    else
      order(:updated_at)
    end
  end
end
