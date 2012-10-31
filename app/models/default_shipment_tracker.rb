class DefaultShipmentTracker
  # Provides tracking information about an order. This stubbed out version just
  # returns the tracking reference.
  #
  # @param Order order
  #
  # @return String
  def track(order)
    order.tracking_reference
  end
end
