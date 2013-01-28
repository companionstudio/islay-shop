class PromotionProductQuantityCondition < PromotionCondition
  desc  "Quantity of Product"

  metadata(:config) do
    foreign_key   :product_id,  :required => true, :values => lambda {Product.tree}
    integer       :quantity,    :required => true, :greater_than => 0, :default => 1
  end

  def qualifications(order)
    items = order.candidate_items.select {|i| i.sku.product_id == product_id}
    items.inject({}) {|h, i| h[i.sku_id] = i.quantity / quantity; h}
  end

  def sku_qualifies?(sku)
    sku.product_id == product_id
  end

  def product_qualifies?(product)
    product.id == product_id
  end

  def qualifies?(order)
    check = order.candidate_items.map do |i|
      i.sku.product_id == product_id and i.quantity >= quantity
    end

    !check.empty? and check.any?
  end

  #'refers to' methods only look at the current level and below. For instance, refers_to_product doesn't consider the category the product is a member of.
  def refers_to_sku?(sku)
    sku.product_id == product_id
  end

  def refers_to_product?(product)
    product.id == product_id
  end

  def specific_to_product?(product)
    product_id == product.id
  end

  def qualifies?(order)
    check = order.candidate_items.map do |i|
      i.sku.product_id == product_id and i.quantity >= quantity
    end

    !check.empty? and check.any?
  end

  def product
    Product.find(product_id) unless product_id == 0
  end

  def products
    top_level = ProductCategory.where('parent_id IS NULL').order('name ASC').includes(:children).includes(:products)

    values = []

    top_level.each do |category|
      if category.children.empty?
        
        products = []
        
        category.products.each do |product|
          products << [product.name, product.id]
        end

        values << [{:label => "#{category.name}", :id => category.id}, products]
        
      else
        category.children.each do |child|
          products = []
          child.products.each do |product|
            products << [product.name, product.id]
          end
          values << [{:label => "#{category.name} - #{child.name}", :id => child.id}, products]
        end
      end
    end

    values
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
    2
  end

end
