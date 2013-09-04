class OrderServiceItem < OrderItem
  belongs_to :service
  belongs_to :order

  attr_accessible :service

  def description
    service.name
  end
end
