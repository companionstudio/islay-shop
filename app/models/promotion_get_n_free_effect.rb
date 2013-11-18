class PromotionGetNFreeEffect < PromotionEffect
  desc "Buy One, Get One (or more) Free"
  condition_scope :sku
  effect_scope :sku_items

  metadata(:config) do
    integer :quantity,  :required => true, :greater_than => 0, :default => 1
  end

  def apply!(order, results)
    messages = results.merged_targets.map do |item, count|
      free = count * quantity
      order.enqueue_adjustment(:bonus_quantity, item.sku, free, 'promotion')
      "Added #{free} of #{item.sku.product.name} - #{item.sku.short_desc} free"
    end

    result(messages.join(', '))
  end
end
