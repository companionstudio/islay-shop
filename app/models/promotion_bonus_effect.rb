class PromotionBonusEffect < PromotionEffect
  desc "Bonus SKU"

  metadata(:config) do
    foreign_key :sku_id,    :required => true, :values => lambda {Sku.all.map {|s| [s.desc, s.id]} }
    integer     :quantity,  :required => true, :greater_than => 0
  end

  def apply!(order)

  end
end
