class PromotionOrderItemQuantityCondition < PromotionCondition
  desc  "Number of items"

  metadata(:config) do
    integer :quantity, :required => true, :greater_than => 0, :default => 0
  end

  def qualifies?(order)
    order.unit_total_quantity >= quantity
  end

  def position
    6
  end

  def qualifications(order)
    {0 => 1}
  end
end
