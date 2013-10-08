class PromotionShippingCondition < PromotionCondition
  desc "Requires an order to have shipping charges"
  condition_scope :shipping_item
  exclusivity_scope :none

  def check(order)
    if order.shipping_total.positive?
      success
    else
      failure(:no_shipping_charges, "Must have a shipping charge")
    end
  end
end
