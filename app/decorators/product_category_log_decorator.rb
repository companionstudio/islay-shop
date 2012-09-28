class ProductCategoryLogDecorator < LogDecorator
  def url
    h.admin_product_category_url(model.id)
  end
end
