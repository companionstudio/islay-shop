class PromotionProductDiscountEffect < PromotionEffect
  include Promotions::DiscountEffectConfig

  desc "Receive a discount on a specific product"
  condition_scope :sku
  effect_scope :sku_items

  def apply!(order, results)
    amount, adjustment = case mode
    when 'percentage' then [BigDecimal.new(percentage.to_s), :percentage_item_discount]
    when 'dollar'     then [dollar, :fixed_item_discount]
    end

    names = results.target_counts.map do |item, count| 
      order.enqueue_adjustment(adjustment, item.sku, count, amount, 'promotion')
      item.sku.short_desc
    end

    result("Discounted #{names.join(', ')} by #{amount_and_mode}")
  end
end
