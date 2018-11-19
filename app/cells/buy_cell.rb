class BuyCell < IslayShopCell
  def add(product)
    @product = product
    render
  end
end
