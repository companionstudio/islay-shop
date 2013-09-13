class PromotionCategoryQuantityCondition < PromotionCondition
  desc "Have a SKU from the specified category"
  condition_scope :sku_items

  metadata(:config) do
    foreign_key :product_category_id, :required => true
    integer     :quantity,            :required => true, :greater_than => 0, :default => 1
  end

  def check(order)
    if qualifying_items(order).sum(&:paid_quantity) >= quantity
      success
    else
      failure
    end
  end

  private

  # Collects an array of items from an order which qualify for this condition.
  #
  # @param Order order
  #
  # @return Array<OrderItem>
  def qualifying_items(order)
    category = ProductCategory.find(product_category_id)
    order.candidate_items.select do |item| 
      item.sku.product.product_category_id == product_category_id or
      item.product.category.path < category.path
    end
  end
end

