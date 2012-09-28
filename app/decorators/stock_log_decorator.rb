class StockLogDecorator < LogDecorator
  def url
    h.admin_product_path(model.parent_id) + '#stock-logs'
  end
end
