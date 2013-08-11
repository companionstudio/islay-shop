class PromotionShippingEffect < PromotionEffect
  desc "Shipping Adjustment"

  metadata(:config) do
    float :amount, :required => true
  end

  def apply!(order, qualifications)
    order.shipping_total = amount
    order.applied_promotions << applications.build(:promotion => promotion)
  end
end