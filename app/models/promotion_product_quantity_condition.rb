class PromotionProductQuantityCondition < PromotionCondition
  desc  "Quantity of Product"

  metadata(:config) do
    foreign_key   :product_id,  :required => true, :values => lambda {Product.all.map {|s| [s.name, s.id]} }
    integer       :quantity,    :required => true, :greater_than => 0, :default => 1
  end

  def qualifies?(order)
    order.items.map {|i| i.sku.product_id}.include?(product_id)
  end
end
