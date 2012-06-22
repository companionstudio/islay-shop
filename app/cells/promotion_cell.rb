class PromotionCell < Cell::Rails
  def category(category)

  end

  def product(product)
    @promotions = Promotion.for_product(product)
    render unless @promotions.empty?
  end

  def sku(sku)

  end
end
