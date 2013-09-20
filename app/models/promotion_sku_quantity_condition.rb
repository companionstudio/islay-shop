class PromotionSkuQuantityCondition < PromotionCondition
  desc  "Quantity of SKU"
  condition_scope :sku_items
  position 3

  metadata(:config) do
    foreign_key   :sku_id,    :required => true
    integer       :quantity,  :required => true, :greater_than => 0, :default => 1
  end

  def check(order)
    item = order.candidate_items.select {|i| i.sku_id == sku_id}.first

    if item.blank?
      message = "Does not contain the product #{sku.product.name} - #{sku.short_desc}; needs at least #{quantity}"
      failure(:no_items, message)
    elsif item.paid_quantity < quantity
      message = "Doesn't have enough of the product #{product.name} - #{sku.short_desc}; needs at least #{quantity}"
      failure(:insufficient_quantity, message)
    else
      success(item => 1)
    end
  end

  # Returns the Sku associated with this condition.
  #
  # @return Sku
  def sku
    @sku ||= Sku.includes(:product).find(sku_id)
  end
end
