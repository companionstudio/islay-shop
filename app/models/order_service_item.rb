class OrderServiceItem < OrderItem
  belongs_to :service

  schema_validations except: :order

  def description
    service.name
  end
end
