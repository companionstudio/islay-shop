class BuyCell < Cell::Rails
  def add(product)
    @product = product
    render
  end
end
