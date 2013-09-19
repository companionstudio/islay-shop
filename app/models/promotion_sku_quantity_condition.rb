class PromotionSkuQuantityCondition < PromotionCondition
  desc  "Quantity of SKU"
  condition_scope :sku_items
  position 3

  metadata(:config) do
    foreign_key   :sku_id,    :required => true
    integer       :quantity,  :required => true, :greater_than => 0, :default => 1
  end

  # Returns the Sku associated with this condition.
  #
  # @return Sku
  def sku
    @sku ||= Sku.includes(:product).find(sku_id)
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
