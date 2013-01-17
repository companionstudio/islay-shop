class PromotionGetNFreeEffect < PromotionEffect
  desc "Buy One, Get One (or more) Free"

  metadata(:config) do
    integer :quantity,  :required => true, :greater_than => 0, :default => 1
  end

  def apply!(order, qualifications)

    skus = Sku.where(:id => qualifications.keys)

    # Provide the cheapest SKU if more than one qualifier is supplied.
    cheapest = skus.reduce do |c, s|
      s.price < c.price || c.blank? ? s : c
    end

    bonus = order.add_bonus_item(cheapest.id, quantity * qualifications.values.reduce(:+))

    order.applied_promotions << applications.build(
      :promotion   => promotion,
      :bonus_item  => bonus
    )
  end
end
