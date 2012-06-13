class PromotionSkuQuantityCondition < PromotionCondition
  include IslayShop::MetaData

  desc  "Quantity of SKU"

  metadata(:config) do
    foreign_key   :sku_id,    :required => true, :values => lambda {Sku.all.map {|s| [s.desc, s.id]} }
    integer       :quantity,  :required => true
  end

  def qualifies?
    false
  end
end
