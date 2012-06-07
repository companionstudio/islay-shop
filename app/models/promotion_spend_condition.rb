class PromotionSpendCondition < PromotionCondition
  key :integer, :minimum, :required => true
  qualification :check_spend

  def check_spend(order)
    order.product_total >= config['minimum']
  end
end
