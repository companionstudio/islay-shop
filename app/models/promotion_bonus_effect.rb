class PromotionBonusEffect < PromotionEffect
  desc "Bonus SKU"

  metadata(:config) do
    foreign_key :sku_id,    :required => true, :values => lambda {Sku.all.map {|s| [s.desc, s.id]} }
    integer     :quantity,  :required => true, :greater_than => 0
  end

  def apply!(order, qualifications)
    qualifications.each do |id, count|
      bonus_item = order.add_bonus_item(id, count)

      applications.build(
        :promotion              => promotion,
        :order                  => order,
        :bonus_order_item       => bonus_item,
        :qualifying_order_item  => order.item_by_sku_id(sku_id)
      )
    end
  end
end
