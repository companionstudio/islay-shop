class PromotionProductQuantityCondition < PromotionCondition
  desc  "Quantity of Product"

  metadata(:config) do
    foreign_key   :product_id,  :required => true, :values => lambda {Product.all.map {|s| [s.name, s.id]} }
    integer       :quantity,    :required => true, :greater_than => 0, :default => 1
  end

  def qualifications(order)
    items = order.candidate_items.select {|i| i.sku.product_id == product_id}
    items.inject({}) {|h, i| h[i.sku_id] = quantity * i.quantity; h}
  end

  def sku_qualifies?(sku)
    sku.product_id == product_id
  end

  def product_qualifies?(product)
    product.id == product_id
  end

  def qualifies?(order)
    order.candidate_items.map {|i| i.sku.product_id}.include?(product_id)
  end
end
