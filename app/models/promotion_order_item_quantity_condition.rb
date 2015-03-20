class PromotionOrderItemQuantityCondition < PromotionCondition
  desc  "Number of items"
  condition_scope :order
  position 6

  metadata(:config) do
    integer :quantity, :required => true, :greater_than => 0, :default => 0
  end

  def check(order)
    if order.sku_unit_quantity >= quantity
      items = order.sku_items.reduce({}) {|h, c| h.merge(c => {:qualifications => 1, :count => c.quantity})}
      puts "Checking Number of items:"
      puts items
      success(items)
    else
      failure(:insufficient_quantity, "Need at least #{quantity} items")
    end
  end
end
