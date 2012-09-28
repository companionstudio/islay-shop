class SkuLogDecorator < LogDecorator
  def url
    h.admin_product_url(model.parent_id)
  end
end
