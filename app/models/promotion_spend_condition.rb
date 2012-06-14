class PromotionSpendCondition < PromotionCondition
  desc  "Minimum Spend"

  metadata(:config) do
    float :amount, :required => true, :greater_than => 0
  end

  def qualifies?(order)
    order.product_total >= amount
  end
end
