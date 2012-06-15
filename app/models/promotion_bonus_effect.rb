class PromotionBonusEffect < PromotionEffect
  desc "Bonus SKU"

  metadata(:config) do
    foreign_key :sku_id,    :required => true, :values => lambda {Sku.all.map {|s| [s.desc, s.id]} }
    integer     :quantity,  :required => true, :greater_than => 0
  end

  def apply!(order, qualifications)
    # We don't care about individual SKUs, just the total number of qualifications
    quantity = qualifications.values.sum
    order.add_item(sku_id, quantity)
  end
end
