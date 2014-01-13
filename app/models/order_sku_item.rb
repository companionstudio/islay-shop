class OrderSkuItem < OrderItem
  belongs_to :sku
  has_one :product, :through => :sku

  attr_accessible(:sku)

  # Generates a description based on the SKU description and product name.
  #
  # @return String
  def description
    "#{sku.product.name} (#{sku.short_desc})"
  end

  # Return the maximum number of this sku that can be purchased
  #
  # @return Integer
  def maximum_quantity_allowed
    sku.stock_level
  end
end
