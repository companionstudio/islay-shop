class OrderServiceItem < OrderItem
  belongs_to :service

  attr_accessible :service

  schema_validations except: :order

  def description
    service.name
  end
end
