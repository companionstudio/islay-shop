class PromotionSpendCondition < PromotionCondition
  desc  "Minimum Spend"
  condition_scope :order
  exclusivity_scope :none
  position 5

  metadata(:config) do
    float :amount, :required => true, :greater_than => 0, :default => 0
  end

  def check(order)
    spend = SpookAndPuff::Money.new(amount.to_s)

    if order.product_total >= spend
      success
    else
      failure(:insufficient_spend, "Must spend at least #{spend}")
    end
  end
end
