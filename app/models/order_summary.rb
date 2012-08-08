class OrderSummary < ActiveRecord::Base
  self.table_name = 'orders'
  has_many :items, :class_name => 'OrderItem', :foreign_key => 'order_id'

  def self.summary
    select(%{
      id, status, name, updated_at,
      '#' || id::text AS reference,
      '$' || TRIM(TO_CHAR(total, '99,999,999.99')) AS formatted_total,
      (SELECT name FROM users WHERE id = updater_id) AS updater_name,
      (SELECT ARRAY_TO_STRING(ARRAY_AGG(ps.name::text || ' (' || ois.quantity::text || ')'), ', ')
       FROM order_items AS ois
       JOIN skus ON skus.id = ois.sku_id
       JOIN products AS ps ON ps.id = skus.product_id
       GROUP BY order_id HAVING order_id = orders.id) AS items_summary
    })
  end

  def self.status_counts
    {
      :billing  => billing.count,
      :packing  => packing.count,
      :shipping => shipping.count,
      :recent   => recently_completed.count
    }
  end

  def self.billing
    where(:status => 'pending')
  end

  PACKING_SELECT = %{
    id, name, updated_at, billing_street, billing_city, billing_state,
    billing_postcode, shipping_street, shipping_city, shipping_state, shipping_postcode,
    '#' || id::text AS reference,
    '$' || TRIM(TO_CHAR(total, '99,999,999.99')) AS formatted_total,
    (SELECT name FROM users WHERE id = updater_id) AS updater_name
  }.freeze

  def self.packing
    select(PACKING_SELECT).where(:status => 'billed')
  end

  def self.shipping
    where(:status => 'packed')
  end

  def self.recently_completed
    where("status = 'complete' AND updated_at >= (NOW() - '7 days'::interval)")
  end

  def self.processing
    where(:status => %w(pending billed packed))
  end

  def self.archived
    where(:status => %w(complete cancelled refunded))
  end

  def self.sorted(s)
    if s
      order(s)
    else
      order(:updated_at)
    end
  end
end
