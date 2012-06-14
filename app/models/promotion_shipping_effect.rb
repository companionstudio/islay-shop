class PromotionShippingEffect < PromotionEffect
  desc "Shipping Adjustment"

  metadata(:config) do
    float :amount, :required => true
  end

  def apply!(order, conditions)

  end
end
