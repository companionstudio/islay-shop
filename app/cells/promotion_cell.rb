class PromotionCell < IslayShop::ApplicationCell
  def category(category)
    @promotions = Promotion.for_category(category)
    render unless @promotions.empty?
  end

  def product(product)
    @promotions = Promotion.for_product(product)
    render unless @promotions.empty?
  end

  def sku(sku)

  end
end
