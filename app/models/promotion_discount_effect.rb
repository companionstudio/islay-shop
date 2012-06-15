class PromotionDiscountEffect < PromotionEffect
  desc "Order Discount"

  metadata(:config) do
    integer :amount, :required => true, :greater_than => 0
  end

  def apply!(order, qualifications)
    order.product_total = order.product_total - amount
  end
end
