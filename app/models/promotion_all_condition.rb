class PromotionAllCondition < PromotionCondition
  desc "All orders qualify"
  condition_scope :order
  exclusivity_scope :full
end
