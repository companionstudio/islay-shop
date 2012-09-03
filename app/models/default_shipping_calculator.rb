class DefaultShippingCalculator
  # Calculates the shipping for an order. This is a stubbed out implementation
  # which gives free shipping. Yay?
  #
  # @param Order order
  #
  # @return Float
  def calculate(order)
    15.0
  end

  # Stubbed out version of this method. Indicates if a caculation is possible.
  #
  # @return Boolean
  def calculate?(order)
    true
  end
end
