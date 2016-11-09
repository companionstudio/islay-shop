class OrderSummary < Order
  # Generates a scope with a bunch of fields calculated for efficiently 
  # reporting on a bunch of orders. It is intended for listing pages and the 
  # like.
  #
  # @return ActiveRecord::Relation
  def self.summary
    select(%{
      id, status, name, updated_at, reference, is_gift,
      total,
      CASE
        WHEN orders.updater_id IS NOT NULL THEN (SELECT name FROM users WHERE id = updater_id)
        ELSE 'Customer'
      END AS updater_name,
      (SELECT ARRAY_TO_STRING(ARRAY_AGG(ps.name::text || ' (' || ois.quantity::text || ')'), ', ')
       FROM order_items AS ois
       JOIN skus ON skus.id = ois.sku_id
       JOIN products AS ps ON ps.id = skus.product_id
       GROUP BY order_id HAVING order_id = orders.id) AS items_summary,
       CASE
         WHEN orders.status = 'pending' AND EXISTS (
           SELECT 1 FROM order_payments AS ops
           WHERE ops.order_id = orders.id 
           AND (ops.provider_expiry IS NOT NULL AND ops.provider_expiry < (NOW() - '3 days'::interval))
         ) THEN true
         ELSE false
       END AS expiring
    })
  end

  def self.status_counts
    {
      :billing  => billing.count,
      :packing  => packing.count,
      :shipping => shipping.count,
      :recent   => recently_completed.count,
      :expiring => expiring.count
    }
  end

  def self.billing
    where(:status => 'pending')
  end

  def self.alt_summary
    select(%{
      id, name, updated_at, billing_street, billing_city, billing_state, reference, use_shipping_address,
      billing_postcode, shipping_street, shipping_city, shipping_state, shipping_postcode, total, is_gift,
      '$' || TRIM(TO_CHAR(total, '99,999,999.99')) AS formatted_total,
      (SELECT name FROM users WHERE id = updater_id) AS updater_name
    })
  end

  # Creates a scope which will find orders which are pending and have a
  # payment method which will expire in three or less days.
  #
  # @return ActiveRecord::Relation
  def self.expiring
    where(%{
      status = 'pending'
      AND EXISTS (
        SELECT 1 FROM order_payments AS ops
        WHERE ops.order_id = orders.id 
        AND (ops.provider_expiry IS NOT NULL AND ops.provider_expiry < (NOW() - '3 days'::interval))
      )
    })
  end

  def self.packing
    where(:status => 'billed')
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
      order("updated_at DESC")
    end
  end
end
