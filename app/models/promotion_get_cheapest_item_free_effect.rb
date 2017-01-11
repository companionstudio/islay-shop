class PromotionGetCheapestItemFreeEffect < PromotionEffect
  desc "Cheapest item free"
  condition_scope :order
  effect_scope :sku_items

  def apply!(order, results)

    #Prep the items so we have individual SKU units, sorted by price
    count = results.target_qualifications.first.last
    qualifiers = results.target_qualifications.reduce([]) do |a, (item, count)|
      item.paid_quantity.times do
         a << item
      end
      a
    end.flatten.sort_by(&:derived_unit_price).first(count)

    messages = qualifiers.map do |item|
      order.enqueue_adjustment(:fixed_item_discount, item.sku, 1, item.derived_unit_price, 'promotion')
      "Discounted #{item} to make it free"
    end

    result(messages.join(', '))
  end
end
