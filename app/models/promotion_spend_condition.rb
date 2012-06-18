class PromotionSpendCondition < PromotionCondition
  desc  "Minimum Spend"

  metadata(:config) do
    float :amount, :required => true, :greater_than => 0, :default => 0
  end

  def qualifies?(order)
    order.product_total >= (amount / 100) # Amount is specified in dollars
  end
end
