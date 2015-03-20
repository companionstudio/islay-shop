class PromotionForEveryQuantityCondition < PromotionCondition
  desc  "For every N items"
  condition_scope :order
  position 7

  metadata(:config) do
    integer :quantity, :required => true, :greater_than => 0, :default => 1
  end

  def check(order)
    count = (order.sku_unit_quantity / quantity).floor

    if count >= 1
      items = order.sku_items.reduce({}) {|h, c| h.merge(c => {:qualifications => count, :count => c.quantity})}
      success(items)
    else
      failure(:insufficient_quantity, "Need at least a quantity of #{quantity} items")
    end
  end
end
