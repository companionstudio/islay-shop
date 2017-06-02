class OrderServiceItem < OrderItem
  belongs_to :service

  def description
    service.name
  end
end
