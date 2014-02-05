class PromotionAllCondition < PromotionCondition
  desc "All orders qualify"
  condition_scope :order
  exclusivity_scope :full
  def check(order)
    success
  end
end
