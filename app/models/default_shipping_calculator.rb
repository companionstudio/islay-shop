class DefaultShippingCalculator
  # Calculates the shipping for an order. This is a stubbed out implementation
  # which gives free shipping. Yay?
  #
  # @param Order order
  # @return SpookAndPuff::Money
  def calculate(order)
    SpookAndPuff::Money.zero
  end
end
