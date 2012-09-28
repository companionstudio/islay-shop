class PriceLogDecorator < LogDecorator
  def url
    h.admin_product_url(model.parent_id) + '#price-logs'
  end
end
