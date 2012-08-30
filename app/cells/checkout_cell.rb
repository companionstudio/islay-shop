class CheckoutCell < Cell::Rails
  def basket(order)
    @order = order
    render
  end

  def form(order)
    @order = order
    render
  end
end
