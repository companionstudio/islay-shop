class PromotionOrderItemQuantityCondition < PromotionCondition
  desc  "Number of items"
  condition_scope :order
  position 6

  metadata(:config) do
    integer :quantity, :required => true, :greater_than => 0, :default => 0
  end

  def check(order)
    if order.sku_unit_quantity >= quantity
      success
    else
      failure(:insufficient_quantity, "Need at least a quantity of #{quantity} items")
    end
  end
end
