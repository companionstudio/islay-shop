class PromotionProductQuantityCondition < PromotionCondition
  desc  "Quantity of Product"
  position 2

  metadata(:config) do
    foreign_key   :product_id,  :required => true
    integer       :quantity,    :required => true, :greater_than => 0, :default => 1
  end

  def check(order)
    check = order.candidate_items.select do |i|
      i.sku.product_id == product_id and i.quantity >= quantity
    end

    if check.empty?
      failure
    else
      targets = check.reduce({}) {|h, c| h.merge(c => c.quantity)}
      success(targets)
    end
  end
end
