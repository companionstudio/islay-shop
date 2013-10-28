class PromotionBonusEffect < PromotionEffect
  desc "Bonus SKU"
  condition_scope :order
  effect_scope :sku_items
  position 3

  metadata(:config) do
    foreign_key :sku_id,    :required => true
    integer     :quantity,  :required => true, :greater_than => 0
  end

  # Returns the Sku associated with this condition.
  #
  # @return Sku
  def sku
    @sku ||= Sku.includes(:product).find(sku_id)
  end

  # When the conditions do not specify a sku, the whole order is considered to 
  # be the qualifying object
  def apply!(order, results)
    order.enqueue_adjustment(:bonus_quantity, sku, quantity, 'promotion')
    message = "Added #{quantity} of bonus item #{sku.product.name} - #{sku.short_desc}"
    result(message)
  end
end
