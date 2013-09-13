class PromotionBonusEffect < PromotionEffect
  desc "Bonus SKU"
  condition_scope :sku_items
  effect_scope :sku_items
  position 3

  metadata(:config) do
    foreign_key :sku_id,    :required => true
    integer     :quantity,  :required => true, :greater_than => 0
    enum        :mode,      :required => %(every once) 
  end

  # When the conditions do not specify a sku, the whole order is considered to 
  # be the qualifying object
  def apply!(order, results)
    # 'every' means for each qualification. 
    # 'once' means once for the whole order.
    bonuses = case mode
    when 'every' then results.targets_sum * quantity
    when 'once' then quantity
    end

    sku = Sku.find(sku_id)
    order.enqueue_adjustment(:bonus_quantity, sku, bonuses, 'promotion')
    message = "Added #{bonuses} of bonus item #{sku.product.name} - #{sku.short_desc}"
    result(message)
  end
end
