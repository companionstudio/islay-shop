class PromotionCategoryQuantityCondition < PromotionCondition
  desc  "Quantity of Product from Category"

  metadata(:config) do
    foreign_key   :product_category_id,  :required => true, :values => lambda {ProductCategory.all.map {|s| [s.name, s.id]} }
    integer       :quantity,             :required => true, :greater_than => 0, :default => 1
  end

  def qualifies?(order)
    order.items.map {|i| i.sku.product.product_category_id}.include?(product_category_id)
  end
end
