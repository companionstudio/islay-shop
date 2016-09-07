class OrderSkuItem < OrderItem
  belongs_to :sku
  has_one :product, :through => :sku

  schema_validations except: :order

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
    if sku.purchase_limiting? and sku.purchase_limit < sku.stock_level
      sku.purchase_limit
    else
      sku.stock_level
    end
  end
end
