class BuyCell < IslayShop::ApplicationCell
  def add(product)
    @product = product
    render
  end
end
