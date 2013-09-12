class PromotionSkuQuantityCondition < PromotionCondition
  desc  "Quantity of SKU"
  position 3

  metadata(:config) do
    foreign_key   :sku_id,    :required => true
    integer       :quantity,  :required => true, :greater_than => 0, :default => 1
  end

  def check(order)
    item = order.candidate_items.select {|i| i.sku_id == sku_id}.first
    if !item.blank? and item.paid_quantity >= quantity
      success(item => 1)
    else
      failure
    end
  end
end
