class PromotionCategoryQuantityCondition < PromotionCondition
  desc  "Quantity of Product from Category" 

  PRODUCT_CATEGORY_VALUES = lambda {
    top_level = ProductCategory.top_level.order('name ASC').includes(:children)

    values = []

    top_level.each do |category|
      if category.children.empty?
        values << [category.name, category.id]
      else
        values << [category.name, category.id]
        children = category.children.each do |child|
          values << ["&nbsp;&nbsp; #{child.name}".html_safe, child.id]
        end
      end
    end

    values
  }

  metadata(:config) do
    foreign_key   :product_category_id,  :required => true, :values => PRODUCT_CATEGORY_VALUES
    integer       :quantity,             :required => true, :greater_than => 0, :default => 1
  end

  def sku_qualifies?(sku)
    sku.product.product_category_id == product_category_id or sku.product.category.parent_id == product_category_id
  end

  def product_qualifies?(product)
    product.product_category_id == product_category_id or product.category.parent_id == product_category_id
  end

  def category_qualifies?(category, recurse = true)
    if recurse
      category.id == product_category_id or category.parent_id == product_category_id
    else
      category.id == product_category_id
    end
  end

  #'refers to' methods only look at the current level and below. For instance, refers_to_product doesn't consider the category the product is a member of.
  def refers_to_category?(category)
    category.id == product_category_id
  end

  def qualifies?(order)
    qualifying_quantity = order.candidate_items.reduce(0) do |h, i|
      if (i.sku.product.product_category_id == product_category_id or i.sku.product.category.parent_id == product_category_id)
        h + i.quantity 
      else
        h
      end
    end
    qualifying_quantity >= quantity
  end

  def qualifications(order)

    #Slurp out the skus from the right category
    qualifiers = order.candidate_items.inject([]) do |h, i|
      if (i.sku.product.product_category_id == product_category_id or i.sku.product.category.parent_id == product_category_id)
        h << {:sku_id => i.sku_id, :price => i.sku.price, :quantity => i.quantity}
      end
    end

    if qualifiers.blank?
      {}
    else
      # Provide the cheapest SKU if more than one sku qualifies
      cheapest = qualifiers.reduce do |c, s|
        s[:price] < c[:price] || c.blank? ? s : c
      end

      {cheapest[:sku_id] => (qualifiers.reduce(0) {|sum, i| sum + i[:quantity]} / quantity).floor}
    end
  end

  def category
    ProductCategory.find(product_category_id)
  end

  def position
    1
  end

end
