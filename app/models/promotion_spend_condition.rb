class PromotionSpendCondition < PromotionCondition
  desc  "Minimum Spend"

  metadata(:config) do
    float :amount, :required => true, :greater_than => 0, :default => 0
  end

  def qualifies?(order)
    order.product_total >= amount
  end

  def position
    5
  end

  def qualifications(order)
    {0 => 1}
  end
end
