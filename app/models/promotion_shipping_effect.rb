class PromotionShippingEffect < PromotionEffect
  key :integer, :total, :required => true
  apply :apply_shipping

  def apply_shipping(order)
    order.shipping_total = config['total']
  end
end
