class PromotionSkuQuantityCondition < PromotionCondition
  desc  "Quantity of SKU"

  metadata(:config) do
    foreign_key   :sku_id,    :required => true, :values => lambda {Sku.all.map {|s| [s.desc, s.id]} }
    integer       :quantity,  :required => true, :greater_than => 0, :default => 1
  end

  def qualifies?(order)
    ids = order.items.map(&:sku_id).include?(sku_id)
  end

  def qualifications(order)
    item = order.items.select {|i| i.sku_id == sku_id}.first
    {item.sku_id => item.quantity / quantity}
  end
end
