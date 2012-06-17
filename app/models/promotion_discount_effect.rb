class PromotionDiscountEffect < PromotionEffect
  desc "Order Discount"

  metadata(:config) do
    enum    :kind,    :required => true, :values => %w(fixed percentage)
    integer :amount,  :required => true, :greater_than => 0
  end

  def apply!(order, qualifications)
    order.product_total = case kind
    when 'percentage' then (amout / order.product_total * 100).round(2)
    when 'fixed'      then order.product_total - amount
    end
  end
end
