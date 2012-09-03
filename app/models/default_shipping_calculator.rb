class DefaultShippingCalculator
  # Calculates the shipping for an order. This is a stubbed out implementation
  # which gives free shipping. Yay?
  #
  # @param Order order
  #
  # @return Float
  def calculate(order)
    if !order.shipping_postcode.blank?
      15.0
    end
  end
end
