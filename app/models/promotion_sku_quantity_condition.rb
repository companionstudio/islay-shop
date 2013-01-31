class PromotionSkuQuantityCondition < PromotionCondition
  desc  "Quantity of SKU"

  metadata(:config) do
    foreign_key   :sku_id,    :required => true, :values => lambda {Sku.tree}
    integer       :quantity,  :required => true, :greater_than => 0, :default => 1
  end

  def qualifies?(order)
    item = order.items.select {|i| i.sku_id == sku_id}.first
    !item.blank? and item.quantity >= quantity
  end

  def qualifications(order)
    item = order.items.select {|i| i.sku_id == sku_id}.first
    {item.sku_id => item.quantity / quantity}
  end

  def refers_to_sku?(sku)
    sku.id == sku_id
  end

  def sku_qualifies?(sku)
    sku.id == sku_id
  end

  def specific_to_sku?(sku)
    sku.id == sku_id
  end

  def specific_to_product?(product)
    sku.product_id == product.id
  end

  def refers_to_product?(product)
    sku.product_id == product.id
  end

  def product
    Product.find(sku.product_id) unless sku_id == 0
  end

  attr_accessor :product_id

  def product_id
    product.id unless sku_id == 0
  end

  def sku
    Sku.find(sku_id) unless sku_id == 0
  end

  def product_categories
    top_level = ProductCategory.where('parent_id IS NULL').order('name ASC').includes(:children)
    values = []
    top_level.each do |category|
      if category.children.empty?
        values << [{:label => category.name, :id => category.id}, [[category.name, category.id]]]
      else
        children = category.children.map do |child|
          [child.name, child.id]
        end
        values << [{:label => category.name, :id => category.id}, children]
      end
    end
    values
  end

  def position
    3
  end
end
