class OrderBonusItem < OrderItem
  before_save :set_price_and_totals

  def price
    0
  end

  def total
    0
  end

  def discount
    100
  end

  private

  def set_price_and_totals
    self.price = 0
    self.total = 0
    self.discount = 100
  end
end
