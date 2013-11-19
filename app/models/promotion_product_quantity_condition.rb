class PromotionProductQuantityCondition < PromotionCondition
  desc  "Quantity of Product"
  condition_scope :sku_items
  exclusivity_scope :sku_items
  position 2

  metadata(:config) do
    foreign_key   :product_id,  :required => true
    integer       :quantity,    :required => true, :greater_than => 0, :default => 1
  end

  def check(order)
    matches = order.candidate_items.select {|i| i.sku.product_id == product_id}
    quantities = matches.select {|i| i.quantity >= quantity}

    if matches.empty?
      message = "Does not contain the product #{product.name}; needs at least #{quantity}"
      failure(:no_items, message)
    elsif quantities.empty?
      message = "Doesn't have enough of the product #{product.name}; needs at least #{quantity}"
      partial(:insufficient_quantities, message)
    else
      targets = quantities.reduce({}) {|h, c| h.merge(c => {:qualifications => 1, :count => c.quantity})}
      success(targets)
    end
  end

  # Returns the product associated with this condition.
  #
  # @return Product
  def product
    @product ||= Product.find(product_id)
  end
end
