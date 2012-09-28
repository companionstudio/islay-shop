class OrderLogDecorator < LogDecorator
  def url
    h.admin_order_url(model.id)
  end
end
