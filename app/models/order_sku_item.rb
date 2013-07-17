class OrderSkuItem < OrderItem
  belongs_to :sku
  has_one :product, :through => :sku

  # Generates a description based on the SKU description and product,
  # otherwise it just uses the product name.
  #
  # @return String
  def description
    if !sku.description.blank?
      "#{sku.product.name} (#{sku.description})"
    else
      "#{sku.product.name} (#{sku.abbreviated_amount})"
    end
  end
end
