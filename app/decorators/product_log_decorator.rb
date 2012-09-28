class ProductLogDecorator < LogDecorator
  def url
    h.admin_product_url(model.id)
  end
end
